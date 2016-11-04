require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/activerecord"
require "./environments"
require "aescrypt"
require "base64"
require "sidekiq"
require "redis"
require "sidekiq/api"
require "sanitize"

$redis = Redis.new(url: (ENV['REDISTOGO_URL'] || 'redis://127.0.0.1:6379'))

class Message < ActiveRecord::Base
  validates :body, length: { minimum: 2 }

  def self.random_name
    [*('a'..'z'),*('0'..'9')].shuffle[0,14].join
  end

  def decrease_views
    self.views_left -= 1
  end
end

class MessageWorker
  include Sidekiq::Worker

  def perform(name)
    Message.find_by(name: name).destroy
  end
end

class MessageSecureService
  def initialize text
    @text = text
  end

  def encrypt(password)
    AESCrypt.encrypt(Sanitize.fragment(@text), password) if @text.length != 0
  end

  def decrypt(password)
    AESCrypt.decrypt(@text, password)
  end
end

class MessageDestroy
  def initialize(message, destroy_type, destroy_value)
    @message = message
    @destroy_type = destroy_type
    @destroy_value = destroy_value
  end

  def destroy_settings
    if @destroy_type == 'views'
      destroy_views
    elsif @destroy_type == 'hours'
      destroy_hours
    end
  end

  def destroy_views
    @message.should_destroy_after_view = true
    @message.views_left = @destroy_value.to_i
    @message
  end

  def destroy_hours
    MessageWorker.perform_at(@destroy_value.to_i.hours.from_now, @message.name)
    @message
  end
end

get '/' do
  erb :"messages/index"
end

get "/messages/create" do
  @message = Message.new
  erb :"messages/create"
end

post "/messages" do
  @message = Message.new(params[:message])
  @message.name = Message.random_name
  @message.body = MessageSecureService.new(@message.body).encrypt(params[:password])

  msg = MessageDestroy.new(@message, params[:destroy_type], params[:destroy_value])
  @message = msg.destroy_settings

  if @message.save
    erb :"/messages/link", locals: {link: "#{request.url}/#{@message.name}"}
  else
    erb :"messages/create"
  end
end

get '/messages/:name' do
  begin
    @message = Message.find_by(name: params[:name])
    erb :"messages/secret"
  rescue
    erb :"messages/not_found"
  end
end

post '/messages/:name' do
  @message = Message.find_by(name: params[:name])

  begin
    @decrypted_message = MessageSecureService.new(@message.body).decrypt(params[:password])

    if @message.should_destroy_after_view
      @message.decrease_views
      @message.save
    end
    erb :"messages/decrypted", locals: {message: @decrypted_message}
  rescue OpenSSL::Cipher::CipherError
    redirect back
  ensure
    if @message.should_destroy_after_view && @message.views_left == 0
      @message.destroy
    end
  end
end
