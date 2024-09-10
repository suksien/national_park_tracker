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

### GET routes
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

get "/:name/" do
  @park = @storage.get_park(params[:name])
  erb :park
end

def valid_date?(date)
  return false if date == ""
  year, month, date = date.split("-")
  return false if year.nil? || month.nil? || date.nil?

  if year.scan(/\D/).empty? & month.scan(/\D/).empty? & date.scan(/\D/).empty?
    year.to_i.between?(1000, 9999) & month.to_i.between?(1, 12) & date.to_i.between?(1, 31)
  else
    false
  end
end

get "/:name/edit" do
  @park = @storage.get_park(params[:name])
  @edit = true
  erb :park
end

# TBC here
get "/visited" do
  @parks = @storage.get_visited_parks
  erb :visited
end

get "/not-yet-visited" do
  @parks = @storage.get_not_visited_parks
  erb :visited
end

### POST routes
post "/:name/edit" do
  @park = @storage.get_park(params[:name])
  
  if params[:date_visited] == "" && @park[:date_visited]
    new_date = @park[:date_visited]
  else
    new_date = params[:date_visited]
  end

  if valid_date?(new_date)
    @storage.update_park_visit(params[:name], new_date, params[:note])
  else
    session[:error] = "Not a valid date. Please enter a date following the YYYY-MM-DD format."
  end
  redirect "/#{params[:name]}/"
end