require 'line/bot'
require 'json'
require 'twitter'
require 'sinatra'

twclient = Twitter::REST::Client.new do |config|
  config.consumer_key        = "7p25lNwshZs7U3KXTtiYOC1eQ"
  config.consumer_secret     = "4Cw01o1okDDPusMbI7tOepxCIqrUuj9SCGWS4P0wyRsyeNn9Hk"
  config.access_token        = "843737242015211522-0Xs9oPLR9T2SKZ8RdhWFEskeKx44wlK"
  config.access_token_secret = "wODQ3Oc3UwPY9fUGySPQm0psYTsKLddzfLKSm50N9i35S"
end

puts twclient.user(928272501943046149).screen_name

def client
  @lineclient ||= Line::Bot::Client.new { |config|
    config.channel_id = "1605768875"
    config.channel_secret = "bb9c0628a8d421316b5d383de5e5883c"
    config.channel_token = "jm1Ux5cgNtwz2taZo0LAxMdrhVsq5/tz6ZJFa+G4P7rdRp9XYIip0cKlG4NQbx2DZfNHw1qJKoFF1wbRcKDEzgx4HNNjmrjjWOSoSLAMBq2SpEzsJtzh2Ez89EpzpSzHGSt+T0hrrfdNa3Dy0VTYOQdB04t89/1O/w1cDnyilFU="
  }
end


def main(event:, context:)
  message = {
  type: 'text',
  text: 'hello'
}
  client.push_message("Ua242d28113c3485e05f8ed896887db25",message)
end

get '/' do
  "Hello World"
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        if event.message['text'] == "hello"
          message = {
            type: 'text',
            text: 'hello!'
          }
        else
          message = {
            type: 'text',
            text: event.message['text']
          }
        end  
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end