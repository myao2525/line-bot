require 'sinatra'
require 'line/bot'

get '/' do
    # list users up and display
    'hello'
end

get '/list/friends' do
    File.open("friend.txt", "r") do |f|
        f.each_line { |line|
            puts line
        }
    end
end

get '/test/push' do
    userId = ENV["LINE_TEST_USER_ID"]
    message = {
        type: 'text',
        text: 'push message'
    }
    response = client.push_message(userId, message)
    p "#{response.code} #{response.body} test"
    p "message to LINE!!"
end

get '/test/profile' do
    userId = ENV["LINE_TEST_USER_ID"]
    response = client.get_profile(userId)
    case response
    when Net::HTTPSuccess then
        contact = JSON.parse(response.body)
        p contact['displayName']
        p contact['pictureUrl']
        p contact['statusMessage']
    else
        p "#{response.code} #{response.body}"
    end
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  unless client.validate_signature(body, request.env['HTTP_X_LINE_SIGNATURE'])
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event

    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
      # 文字列が入力された場合
      case event.message['text']
      when 'おはよう'
        message = [{
          type: 'text',
          text: 'Hi! test OK!'
        }
      when 'バイバイ'
        # 「バイバイ」と入力されたときの処理
        message = [{
          type: 'text',
          text: 'Bye Bye!'
        }
      else # オウム返し
        message = {
          type: 'text',
          text: event.message['text']
        }

        client.reply_message(event['replyToken'], message)
      end

      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end

      when Line::Bot::Event::MessageType::Location
        # 位置情報が入力された場合
        latitude = event.message['latitude'] # 緯度
        longitude = event.message['longitude'] # 経度

        # 経度・経度を使った処理
      end

    when Line::Bot::Event::Follow
        message = [{
          type: 'text',
          text: '追加してくれてありがと！'
        },
        {
          type: 'text',
          text: event['source']['userId']
        }]
        File.open("friend.txt", "a") do |f|
            f.puts event['source']['userId']+"\n"
        end
        client.reply_message(event['replyToken'], message)
    end
  }

  "OK"
end
