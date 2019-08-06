require 'line/bot'
require 'twitter'
require 'sinatra'
require 'dotenv/load'

def client 
  @twclient ||= Twitter::REST::Client.new { |config|
    config.consumer_key        = ENV['tw_con_KEY']
    config.consumer_secret     = ENV['tw_con_s_KEY']
    config.access_token        = ENV['tw_access_t']
    config.access_token_secret = ENV['tw_access_t_s']
  }
end

def lineclient
  @lineclient ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV['li_ch_id']
    config.channel_secret = ENV['li_ch_secret']
    config.channel_token = ENV['li_ch_token']
  }
end

def toLINE(string)
  message = {
  type: 'text',
  text: string
  }
  lineclient.push_message("Ua242d28113c3485e05f8ed896887db25",message)
end

def toLINEi(url)
  imagem = {
      type: "image",       
      originalContentUrl: url,
      previewImageUrl: "https://example.com/preview.jpg"
  }
  lineclient.push_message("Ua242d28113c3485e05f8ed896887db25",imagem)
end

def toLINEv(url)
  video = {
        type: "video",       
        originalContentUrl: url,
        previewImageUrl: "https://example.com/preview.jpg"
    }
  lineclient.push_message("Ua242d28113c3485e05f8ed896887db25",video)
end

def getiine(s)
  ago = (((Time.now).to_s.slice(/\d+/).to_i)-1).to_s #1年前
  kyonen = ago + (Time.now).to_s.slice(4, 6)
  kyonen = s if s.delete("-").to_f.to_s.size() == 10
  nitizi = kyonen + "のいいね"
  toLINE(nitizi)
  tw = []
  
  def collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end
  
  def client.get_all_tweets(user)
    collect_with_max_id do |max_id|
      options = {count: 200, include_rts: true}
      options[:max_id] = max_id unless max_id.nil?
      favorites(user, options)
    end
  end
  
  client.get_all_tweets(928272501943046149).each do |tweet|
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
  linetext = event.message['text']
  if linetext == "get"
    getiine(linetext)
  elsif linetext.delete("-").to_f.to_s.size() == 10
    getiine(linetext)
  else
    message = {
      type: 'text',
      text: linetext
    }
  end  
  lineclient.reply_message(event['replyToken'], message)
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless lineclient.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = lineclient.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        mes(event)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = lineclient.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end