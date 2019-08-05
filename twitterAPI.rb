require 'line/bot'
require 'json'
require 'twitter'
require 'sinatra'

def twclient 
  @twclient ||= Twitter::REST::Client.new { |config|
    config.consumer_key        = "7p25lNwshZs7U3KXTtiYOC1eQ"
    config.consumer_secret     = "4Cw01o1okDDPusMbI7tOepxCIqrUuj9SCGWS4P0wyRsyeNn9Hk"
    config.access_token        = "843737242015211522-0Xs9oPLR9T2SKZ8RdhWFEskeKx44wlK"
    config.access_token_secret = "wODQ3Oc3UwPY9fUGySPQm0psYTsKLddzfLKSm50N9i35S"
  }
end


def client
  @lineclient ||= Line::Bot::Client.new { |config|
    config.channel_id = "1605768875"
    config.channel_secret = "bb9c0628a8d421316b5d383de5e5883c"
    config.channel_token = "jm1Ux5cgNtwz2taZo0LAxMdrhVsq5/tz6ZJFa+G4P7rdRp9XYIip0cKlG4NQbx2DZfNHw1qJKoFF1wbRcKDEzgx4HNNjmrjjWOSoSLAMBq2SpEzsJtzh2Ez89EpzpSzHGSt+T0hrrfdNa3Dy0VTYOQdB04t89/1O/w1cDnyilFU="
  }
end



def toLINE(m)
  message = {
  type: 'text',
  text: m
  }
  client.push_message("Ua242d28113c3485e05f8ed896887db25",message)
end

def toLINEi(url)
  imagem = {
      type: "image",       
      originalContentUrl: url,
      previewImageUrl: "https://example.com/preview.jpg"
  }
  client.push_message("Ua242d28113c3485e05f8ed896887db25",imagem)
end

def toLINEv(url)
  video = {
        type: "video",       
        originalContentUrl: url,
        previewImageUrl: "https://example.com/preview.jpg"
    }
  client.push_message("Ua242d28113c3485e05f8ed896887db25",video)
end



def collect_with_max_id(collection=[], max_id=nil, &block)
  response = yield(max_id)
  collection += response
  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def self.get_all_tweets(user)
  collect_with_max_id do |max_id|
    options = {count: 200, include_rts: true}
    options[:max_id] = max_id unless max_id.nil?
    favorites(user, options)
  end
end

def getiine

  ago = (((Time.now).to_s.slice(/\d+/).to_i)-1).to_s #1年前
  kyonen = ago + (Time.now).to_s.slice(4, 6)
  nitizi = kyonen + "のいいね"
  toLINE(nitizi)
  tw = []
  
  twclient.get_all_tweets(928272501943046149).each do |tweet|
    
    if tweet.created_at.to_s.include?(kyonen)
      tw << tweet
    end
  end
  
  tw = tw.sort_by {|t| t.created_at }
  
  tw.each do |tweet|
    if tweet.media[0]
      if tweet.media[0].type == "animated_gif" || tweet.media[0].type == "video"
        toLINEv(tweet.media[0].video_info.variants[0].url)
      elsif tweet.media[0].type == "photo"  
        toLINEi(tweet.media[0].media_url_https)  if tweet.media[0]
        toLINEi(tweet.media[1].media_url_https)  if tweet.media[1]
        toLINEi(tweet.media[2].media_url_https)  if tweet.media[2]
        toLINEi(tweet.media[3].media_url_https)  if tweet.media[3]
      end
      
      toLINE(tweet.full_text)
      toLINE(tweet.url) unless tweet.media[0]
      
    end
  end
end

get '/' do
  "Hello World"
end

def mes(event)
  if event.message['text'] == "hello"
    message = {
      type: 'text',
      text: 'hello!'
    }
  elsif event.message['text'] == "get"
    getiine
  else
    message = {
      type: 'text',
      text: event.message['text']
    }
  end  
  client.reply_message(event['replyToken'], message)
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
        mes(event)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end