require 'rubygems'
require 'sinatra'
require 'haml'
require 'sqlite3'
require 'sequel'
require 'sanitize'

require './server.rb'

run Sinatra::Application
