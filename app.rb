require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require_relative "database_persistence"
require "pry"
require "date"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  also_reload "database_persistence.rb"
end

helpers do
  def sort_parks(parks, criteria)
    case criteria
    when "state" then parks.sort_by { |park| park[:state] }
    when "year" then parks.sort_by { |park| DateTime.parse(park[:date_established]).to_date }
    when "area" then parks.sort_by { |park| park[:area_km2] }
    end
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

## GET routes
get "/" do
  @parks = @storage.get_all_parks
  erb :homepage
end

get "/parks-by-state" do
  @parks = @storage.get_all_parks
  @criteria = "state"
  erb :sort_parks
end

get "/parks-by-year" do
  @parks = @storage.get_all_parks
  @criteria = "year"
  erb :sort_parks
end

get "/parks-by-area" do
  @parks = @storage.get_all_parks
  @criteria = "area"
  erb :sort_parks
end