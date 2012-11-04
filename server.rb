# -*- coding: utf-8 -*-
if development?
  require 'sinatra/reloader'
end

enable :sessions, :logging

use OmniAuth::Builder do
  config = YAML.load_file("config.yml")
  provider :twitter, config["CONSUMER_KEY"], config["CONSUMER_SECRET"]
end


Sequel::Model.plugin(:schema)
Sequel.sqlite('db/links.db')
class Entries < Sequel::Model
  plugin :timestamps, :update_on_create => true
  unless table_exists?
    set_schema do
      primary_key :id
      string :url
      string :title
      timestamp :created_at
      timestamp :updated_at
    end
    create_table
  end
end



get '/' do
  @title = 'Links!!'
  @entries = Entries.all
  haml :index
end

post '/add' do
  @title = 'Links!!'
  @entry = Entries.new :url => Sanitize.clean(params[:url]), :title => title(add_schema(params[:url]))
  @entry.save
  redirect '/'
end

get '/auth/:name/callback' do
  @auth = request.env['omniauth.auth']
  haml :index
end

helpers do
  def add_schema(url)
    if url !~ /^https?/
      if url !~ /\/\//
        "http:#{url}"
      else
        "http://#{url}"
      end
    else
      url
    end
  end
  
  def shorten(str, max = 20)
    if str.length > max
      "#{str[0..max.to_i]}..."
    else
      str
    end
  end


  def timefmt(time)
    if time
      time.strftime("%Y-%m-%d %H:%M:%S")
    else
      ''
    end
  end

  def hatebu(url)
    '<a href="http://b.hatena.ne.jp/entry/' + url + '" class="hatena-bookmark-button" data-hatena-bookmark-layout="simple-balloon" title="このエントリーをはてなブックマークに追加"><img src="http://b.st-hatena.com/images/entry-button/button-only.gif" alt="このエントリーをはてなブックマークに追加" width="20" height="20" style="border: none;" /></a>'
  end

  def twitter(url)
    '<a href="https://twitter.com/share" class="twitter-share-button" data-url="' + url + '" data-via="" data-lang="ja">ツイート</a>'
  end

  def google(url)
    '<div class="g-plusone" data-size="medium" data-href="' + url + '"></div>'
  end

  def title(url)
    agent = Mechanize.new
    agent.get(url)
    agent.page.title    
  end

  def capture(url)
    '<img class="alignleft" align="left" border="0" src="http://capture.heartrails.com/150x130/shadow?' + url +'" alt="" width="150" height="130" />'
  end

 
end

