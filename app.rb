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
  # def sort_parks(parks, criteria)
  #   case criteria
  #   when "state" then parks.sort_by { |park| park[:state] }
  #   when "year" then parks.sort_by { |park| DateTime.parse(park[:date_established]).to_date }
  #   when "area" then parks.sort_by { |park| park[:area_km2] }
  #   when "id" then parks.sort_by { |park| park[:id] }
  #   end
  # end

  def sort_parks(parks, criteria)
    if criteria == "year"
      parks.sort_by { |park| DateTime.parse(park[:date_established]).to_date }
    else
      parks.sort_by { |park| park[criteria.to_sym] }
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
  @criteria = "area_km2"
  erb :sort_parks
end

get "/:name/" do
  @park = @storage.get_park(params[:name])
  erb :park
end

get "/:name/edit" do
  @park = @storage.get_park(params[:name])
  @edit = true
  erb :park
end

get "/visited" do
  @visited = true
  @parks = @storage.get_visited_parks(@visited)
  erb :visited
end

get "/not-yet-visited" do
  @visited = false
  @parks = @storage.get_visited_parks(@visited)
  erb :visited
end

get "/add-park" do
  erb :add_park
end

def valid_name?(name)
  name.size > 0
end

def valid_state?(state)
  state.size > 0
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

def valid_area?(area)
  area.to_i > 0
end

def valid_desc?(desc)
  desc.size > 0
end

def valid_park?(name, state, date, area, desc)
  valid_name?(name) & valid_state?(state) & valid_date?(date) & valid_area?(area) & valid_desc?(desc)
end

### POST routes
post "/add-park/" do
  name, state, date, area, desc = params[:name], params[:state], params[:date], params[:area_km2], params[:description]   
  
  if valid_park?(name, state, date, area, desc)
    @storage.insert_park(name, state, date, area, desc)
    redirect "/"
  else
    if !valid_name?(name)
      session[:error] = "Invalid park name."
    elsif !valid_state?(state)
      session[:error] = "Invalid state name."
    elsif !valid_date?(date)
      session[:error] = "Invalid date."
    elsif !valid_area?(area)
      session[:error] = "Invalid area."
    else
      session[:error] = "Invalid description."
    end
    redirect "/add-park"
  end
end

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