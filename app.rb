require 'bundler/setup'
require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "bcrypt"
require "date"
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

##### helper methods
def check_user_is_signed_in
  unless session[:username]
    session[:error] = "Please sign in first."
    session[:original_request] = request.path_info
    redirect "/users/signin"
  end
end

def park_exists?(name)
  @storage.has_park?(name.downcase)
end

def valid_name?(name)
  name.strip.size > 0
end

def valid_state?(state)
  state.strip.size > 0
end

def valid_date?(date)
  return false if date == ""
  year, month, date = date.split("-")
  return false if year.nil? || month.nil? || date.nil?
  return false if month.size > 2 || date.size > 2

  if year.scan(/\D/).empty? & month.scan(/\D/).empty? & date.scan(/\D/).empty? & year.to_i.between?(1000, 9999) & month.to_i.between?(1, 12)
    begin
      d = Date.new(year.to_i, month.to_i, date.to_i)
    rescue Date::Error
      false
    end
    d <= Date.today
  else
    false
  end
end

def valid_area?(area)
  area.to_i > 0
end

def valid_desc?(desc)
  desc.strip.size > 0
end

def edit_park_no_changes?(park, new_name, new_state, new_date, new_area, new_desc)
  park[:name] == new_name && \
  park[:state] == new_state && \
  park[:date_established] == new_date && \
  park[:area_km2] == new_area.to_i && \
  park[:description] == new_desc
end

def get_last_page(ntot_items, max_output)
  (ntot_items * 1.0 / max_output).ceil
end

def valid_page_number?(ntot_items, page_num, max_output)
  return true if ntot_items == 0 && page_num == 1
  page_num >= 1 && page_num <= get_last_page(ntot_items, max_output)
end

def load_park(park_name)
  park = @storage.get_park(park_name)
  return park if park
  
  session[:error] = "The park cannot be found."
  redirect "/"
end

def load_visit(visit_id, park_name)
  visits = @storage.get_visit(visit_id)
  return visits if visits

  session[:error] = "The visit cannot be found."
  redirect "/parks/#{park_name}/visits/page=1"
end

def visit_exists?(park_name, date_visited)
  @storage.visit_exists?(park_name, date_visited)
end

def validate_input_for_park(input_name, input_state, input_date, input_area, input_desc)
  error_msgs = []

  error_msgs << "Invalid park name." if !valid_name?(input_name)
  error_msgs << "Invalid state name." if !valid_state?(input_state)
  error_msgs << "Invalid date." if !valid_date?(input_date)
  error_msgs << "Invalid area." if !valid_area?(input_area)
  error_msgs << "Invalid description."  if !valid_desc?(input_desc)
  
  return error_msgs
end

def validate_input_for_visits(input_date, input_note)
  error_msgs = []
  error_msgs << "Invalid date." if !valid_date?(input_date)

  if input_note != ""
    error_msgs << "Invalid visit note." if !valid_desc?(input_note)
  end

  return error_msgs
end

##### GET routes
not_found do
  session[:error] = "The requested page is not found. Redirecting to home page..."
  redirect "/"
end

get "/" do
  redirect "/parks/page=1"
end

# load sign in page
get "/users/signin" do
  erb :signin
end

# homepage -- display all parks in sets of 5 at a time
# unknown routes will be redirected here
get "/parks/page=:page" do
  @max_output = 5
  @page_num = params[:page].to_i
  @nparks = @storage.count_parks.to_i
  
  if valid_page_number?(@nparks, @page_num, @max_output)
    @parks = @storage.get_all_parks(@max_output, @page_num)
    @last_page = (@nparks * 1.0 / @max_output).ceil
    erb :homepage
  else
    session[:error] = "Invalid page number."
    redirect "/parks/page=1" if @page_num < 1
    
    last_page = get_last_page(@nparks, @max_output)
    redirect "/parks/page=#{last_page}" if @page_num > last_page
  end

end

# display info and visit history for a park
get "/parks/:name/visits/page=:page" do
  check_user_is_signed_in

  @park = load_park(params[:name])
  @nvisits = @storage.count_park_visits(@park[:id]).to_i
  @max_output = 3
  @page_num = params[:page].to_i

  if valid_page_number?(@nvisits, @page_num, @max_output)
    @park_visits = @storage.get_park_visits(@park[:id], @max_output, @page_num)
    erb :park
  else
    session[:error] = "Invalid page number."
    redirect "/parks/#{params[:name]}/visits/page=1" if @page_num < 1

    last_page = get_last_page(@nvisits, @max_output)
    redirect "/parks/#{params[:name]}/visits/page=#{last_page}" if @page_num > last_page
  end

end

# load page to edit park info
get "/parks/:name/edit" do
  check_user_is_signed_in
  @park = load_park(params[:name])
  erb :edit_park
end

# load page to add a visit to a park
get "/parks/:name/add_visit" do
  check_user_is_signed_in

  @park_name = params[:name]
  erb :add_visit
end

# load page to edit a visit
get "/parks/:name/visits/:visit_id/edit" do
  check_user_is_signed_in
  @visit = load_visit(params[:visit_id].to_i, params[:name])
  erb :edit_visit
end

# load page to add a new park
get "/parks/add-park" do
  check_user_is_signed_in
  erb :add_park
end

##### POST routes

# sign a user in
post "/users/signin" do
  username = params[:username]
  password = params[:password]

  if @storage.valid_user?(username, password)
    session[:message] = "Welcome, #{username}!"
    session[:username] = username
    redirect session[:original_request]
  else
    session[:error] = "Wrong username and/or password. Please try again."
    erb :signin
  end
end

# sign a user out
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

# add a new park
post "/parks/add-park/" do
  check_user_is_signed_in

  name, state, date, area, desc = params[:name], params[:state], params[:date], params[:area_km2], params[:description]
  name = name.strip

  @park_name, @park_state, @park_date, @park_area, @park_desc = name, state, date, area, desc

  if park_exists?(name)
    session[:error] = ["#{name} already exists. Please enter a new park!"]
    erb :add_park
  else
    error_msgs = validate_input_for_park(name, state, date, area, desc)

    if error_msgs.empty?
      @storage.insert_park(@park_name, @park_state, @park_date, @park_area, @park_desc)
      session[:message] = "#{@park_name} has been added."
      redirect "/"
    else
      session[:error] = error_msgs
      erb :add_park
    end
  end
end

# delete a park
post "/parks/:name/delete" do
  check_user_is_signed_in

  @storage.delete_park(params[:name])
  session[:message] = "#{params[:name]} has been deleted."
  redirect "/"
end

# edit a park info
post "/parks/:name/edit" do
  check_user_is_signed_in

  new_name, new_state, new_date, new_area, new_desc = params[:park_name], params[:state], params[:date], params[:area_km2], params[:description]
  new_name = new_name.strip

  @park = load_park(params[:name])
 
  error_msgs = []
  if edit_park_no_changes?(@park, new_name, new_state, new_date, new_area, new_desc)
    error_msgs = ["No changes has been detected."]
  else
    @new_name, @new_state, @new_date, @new_area, @new_desc = new_name, new_state, new_date, new_area, new_desc
    error_msgs = validate_input_for_park(new_name, new_state, new_date, new_area, new_desc)
  end

  if error_msgs.empty?
    @storage.update_park(@park[:id], @new_name, @new_state, @new_date, @new_area, @new_desc)
    session[:message] = "Park info has been updated."
    redirect "/parks/#{@new_name}/visits/page=1"
  else
    session[:error] = error_msgs
    erb :edit_park
  end

end

# add a park visit
post "/parks/:name/add_visit" do
  check_user_is_signed_in

  park_name, date_visited, visit_note = params[:name], params[:date_visited], params[:visit_note]

  @visit_date, @visit_note = date_visited, visit_note

  if valid_date?(date_visited) && visit_exists?(park_name, date_visited)
    session[:error] = ["This visit already exists. Please enter a new visit!"]
    erb :add_visit
  else
    error_msgs = validate_input_for_visits(date_visited, visit_note)

    if error_msgs.empty?
      @storage.add_visit(park_name, @visit_date, @visit_note)
      session[:message] = "A new visit has been added."
      redirect "/parks/#{park_name}/visits/page=1"
    else
      session[:error] = error_msgs
      erb :add_visit
    end
  end
end

# delete a park visit
post "/parks/:name/visits/:visit_id/delete" do
  check_user_is_signed_in

  @storage.delete_visit(params[:visit_id].to_i)
  session[:message] = "Visit has been deleted."
  redirect "/parks/#{params[:name]}/visits/page=1"
end

# edit a park visit
post "/parks/:name/visits/:visit_id/edit" do
  check_user_is_signed_in

  new_date, new_note = params[:date_visited], params[:visit_note]
  @visit = load_visit(params[:visit_id].to_i, params[:name])

  @new_date, @new_note = new_date, new_note

  if new_date == @visit[:date_visited] && new_note == @visit[:note]
    error_msgs = ["No changes has been detected."]
  else
    error_msgs = validate_input_for_visits(new_date, new_note)
  end

  if error_msgs.empty?
    @storage.update_visit(params[:visit_id].to_i, new_date, new_note)
    session[:message] = "Visit info has been updated."
    redirect "/parks/#{params[:name]}/visits/page=1"
  else
    session[:error] = error_msgs
    erb :edit_visit
  end
end