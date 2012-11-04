require 'rubygems'
require 'sinatra'
require 'haml'
require 'sqlite3'
require 'sequel'
require 'sanitize'
require 'mechanize'
require 'omniauth'
require 'yaml'

require './server.rb'

run Sinatra::Application
