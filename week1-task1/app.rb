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

class MessageWorker
  include Sidekiq::Worker

  def perform(name)
    Message.find_by(name: name).destroy
  end
end

class Message < ActiveRecord::Base
  validates :body, length: { minimum: 2 }
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
  @message.name = [*('a'..'z'),*('0'..'9')].shuffle[0,14].join
  @message.body = AESCrypt.encrypt(Sanitize.fragment(@message.body), params[:password]) if @message.body.length != 0

  if params[:destroy_type] == 'views'
    @message.should_destroy_after_view = true
    @message.views_left = params[:destroy_value].to_i
  elsif params[:destroy_type] == 'hours'
    destroy_value = params[:destroy_value].to_i
    MessageWorker.perform_at(destroy_value.hours.from_now, @message.name)
  end

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
  puts params
  @message = Message.find_by(name: params[:name])

  begin
    @decrypted_message = AESCrypt.decrypt(@message.body, params[:password])

    if @message.should_destroy_after_view
      @message.views_left -= 1
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
