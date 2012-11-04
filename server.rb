# -*- coding: undecided -*-
if development?
  require 'sinatra/reloader'
end

Sequel::Model.plugin(:schema)

Sequel.sqlite('db/links.db')
class Entries < Sequel::Model
  plugin :timestamps, :update_on_create => true
  unless table_exists?
    set_schema do
      primary_key :id
      string :url
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
  @entry = Entries.new :url => Sanitize.clean(params[:url])
  @entry.save
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
    '<a href="http://b.hatena.ne.jp/entry/' + url + '" class="hatena-bookmark-button" data-hatena-bookmark-layout="simple-balloon" title="このエントリーをはてなブックマークに追加"><img src="http://b.st-hatena.com/images/entry-button/button-only.gif" alt="このエントリーをはてなブックマークに追加" width="20" height="20" style="border: none;" /></a><script type="text/javascript" src="http://b.st-hatena.com/js/bookmark_button.js" charset="utf-8" async="async"></script>'
  end
end

