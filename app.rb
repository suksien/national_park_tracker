require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

## GET routes
get "/" do
  "Getting started."
  erb :homepage
end