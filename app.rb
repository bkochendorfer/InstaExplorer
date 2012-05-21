require "sinatra"
require "instagram"
require "geokit"
require "haml"
require "hashie"


enable :sessions
set :session_secret, ENV['SESSION_SECRET'] ||= "something"
set :protection, except: :session_hijacking

CALLBACK_URL = "http://instaexplorer.heroku.com/oauth/callback"

Instagram.configure do |config|
  config.client_id = "033ac32990c440b680a588529d7ee35d"
  config.client_secret = "efc9a56b44744cce994bfe099caabb2e"
end

get "/" do
  redirect "/search"
end

get "/oauth/connect" do
  puts redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL, :scope => "likes", :scope => "relationships")
end

get "/oauth/callback" do
  response_insta = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response_insta.access_token
  session[:user] = response_insta.user.username
  session[:user_photo] = response_insta.user.profile_picture
  session['instagram_auth'] = "true"
  redirect "/by/#{session[:redirect_user]}"
end

get "/search" do
  get_user_status
  @media_items = []
  @location = Geokit::Geocoders::YahooGeocoder.geocode session[:last_search] || "#{request.ip}"
  @media_items = Instagram.media_search(@location.lat, @location.lng)
  store_search
  haml :address  
end

post "/search" do
  get_user_status
  @media_items = []
  @location = Geokit::Geocoders::YahooGeocoder.geocode "#{params[:address]}"
  @media_items = Instagram.media_search(@location.lat, @location.lng)
  store_search
  haml :search_results
end

get "/by/:name" do
  unless session['instagram_auth'] == "true"
    session[:redirect_user] = "#{params[:name]}"
    redirect "/oauth/connect"
  end
  get_user_status
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  user_search = Instagram.user_search(params[:name])
  user_id = user_search.map {|get| get.id}
  @media_feed = Instagram.user_recent_media(user_id[0].to_i, :access_token => session[:access_token]).select {|photo| photo.location?}
  haml :by
end

post "/by/:name" do
  @location = Geokit::Geocoders::YahooGeocoder.geocode "#{params[:address]}"
  store_search
  redirect "/search"  
end

get "/like/:id" do
  Instagram.like_media(params[:id], :access_token => session[:access_token])
end

get "/follow/:id" do
  Instagram.follow_user(params[:id], :access_token => session[:access_token])
end

get "/*" do
  redirect "/"
end

def get_user_status
 if session[:user] 
    @current_user = session[:user]
  else
    @current_user = "<a href=\"/oauth/connect\">Connect with Instagram</a>" 
    session[:user_photo] = "/images/Instagram_Icon_Small.png"
  end
end

def store_search
  session[:last_search] = "#{@location.lat}, #{@location.lng}"
end 
