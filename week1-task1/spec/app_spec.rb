require File.expand_path '../spec_helper.rb', __FILE__

describe "Secure Messages Application" do
  it "should allow accessing the home page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include("Create and share secure messages!")
  end

  it "should allow accessing message creation page" do
    get '/messages/create'
    expect(last_response).to be_ok
    expect(last_response.body).to include("Create Secure Message")
    expect(last_response.body).to include("message_body")
    expect(last_response.body).to include("message_password")
    expect(last_response.body).to include("destroy_value")
    expect(last_response.body).to include("destroy_type")
  end

  it "should not allow creating an empty message" do
    post '/messages'
    expect(last_response.status).to eq(500)
  end

  it "should allow creating a message with time limits" do
    @passed_message = {body: "test body"}
    post '/messages', message: @passed_message, password: "testpass", destroy_value: "3", destroy_type: "hours"

    @expected_message = Message.last
    expect(@expected_message.body).not_to eql(@passed_message[:body])
    expect(@expected_message.name.length).to eql(14)
    expect(@expected_message.should_destroy_after_view).to eql(nil)
    expect(@expected_message.views_left).to eql(nil)

    expect(last_response.body).to include("Your link is")
  end

  it "should allow creating a message with view limits" do
    @passed_message = {body: "test body"}
    post '/messages', message: @passed_message, password: "testpass", destroy_value: "3", destroy_type: "views"

    @expected_message = Message.last
    expect(@expected_message.body).not_to eql(@passed_message[:body]) #expected_message body is ecnrypted
    expect(@expected_message.name.length).to eql(14)
    expect(@expected_message.should_destroy_after_view).to eql(true)
    expect(@expected_message.views_left).to eql(3)

    expect(last_response.body).to include("Your link is")
  end

  describe "Requesting Message" do
    before(:each) do
      @passed_message = {body: "test body"}
      post '/messages', message: @passed_message, password: "testpass", destroy_value: "2", destroy_type: "views"
      @message = Message.last
    end

    it "should show 'Not Found' message, if message does not exist" do
      get '/messages/hellothere'
      expect(last_response.body).to include("This message does not exist")
    end

    it "should show password prompt when message is requested" do
      get "/messages/#{@message.name}"
      expect(last_response.body).to include("Please enter password to view the message")
    end

    it "should redirect to password prompt, if password is incorrect" do
      post "/messages/#{@message.name}", password: "this should not work"
      expect(last_response.status).to eql(302)
      expect(Message.last.views_left).to eql(2)
    end

    it "should show message and decrease views_left" do
      post "/messages/#{@message.name}", password: "testpass"
      expect(last_response).to be_ok
      expect(last_response.body).to include("test body")
      expect(Message.last.views_left).to eql(1)
    end

    it "should destroy message if there are no views left" do
      3.times do
        post "/messages/#{@message.name}", password: "testpass"
      end

      expect(last_response.body).to include("This message does not exist")
    end
  end
end
