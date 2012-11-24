# -*- coding: utf-8 -*-
if development?
  require 'sinatra/reloader'
end


config = YAML.load_file("config.yml")

set :session, true
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :twitter, config["CONSUMER_KEY"], config["CONSUMER_SECRET"]
end


Sequel::Model.plugin(:schema)
Sequel.sqlite('db/links.db')
class Entries < Sequel::Model
  plugin :timestamps, :update_on_create => true
  unless table_exists?
    set_schema do
      primary_key :id
      integer :order
      string :url
      string :title
      string :tags
      timestamp :created_at
      timestamp :updated_at
    end
    create_table
  end
end

before do
  @linktags = ['windows', 'exchange']  
end



get '/' do
  @title = 'リンク集'

  if session[:nickname] == config["ADMIN_NAME"]
    @admin_mode = true
  else
    @admin_mode = false
  end

  @entries = Entries.order(:order).all
  haml :index
end

get '/logout' do
  session[:nickname] = nil
  redirect '/'
end


get '/:tag' do
  @admin_mode = false

  @title = params[:tag]
  @entries = Entries.order(:order).filter(:tags.ilike("%[" + @title + "]%"))
  haml :index
end

post '/add' do
  new_entry = Entries.new :url => Sanitize.clean(params[:url]), :title => title(add_schema(params[:url]))
  new_entry.save
  new_entry.update(:order => new_entry.id.to_i)
  new_entry.update(:tags => params[:tags])

  redirect '/'
end

post '/remove' do
  target_link = Entries[:order => params[:order]]
  target_link.delete

  redirect '/'
end

post '/move_up' do
  if params[:order] == '1'
    redirect '/'
  end

  target_link = Entries[:order => params[:order]]
  before_link = Entries[:order => params[:order].to_i - 1]

  target_link.update(:order => target_link.order.to_i - 1)
  before_link.update(:order => before_link.order.to_i + 1)

  redirect '/'
end

post '/move_down' do
  if params[:order].to_i == Entries.all.length
    redirect '/'
  end

  target_link = Entries[:order => params[:order]]
  next_link = Entries[:order => params[:order].to_i + 1]

  target_link.update(:order => target_link.order.to_i + 1)
  next_link.update(:order => next_link.order.to_i - 1)

  redirect '/'
end

post '/change_tag' do
  target_link = Entries[:order => params[:order]]
  target_link.update(:tags => params[:tags])
  
  redirect '/'
end


get '/auth/:name/callback' do
  @auth = request.env['omniauth.auth']
  session[:nickname] = @auth["info"]["nickname"]
  redirect '/'
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

