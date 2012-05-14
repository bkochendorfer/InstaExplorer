require "sinatra"
require "instagram"
require "geokit"
require "haml"
require "hashie"

enable :sessions


CALLBACK_URL = "http://localhost:9393/oauth/callback"

Instagram.configure do |config|
  config.client_id = "033ac32990c440b680a588529d7ee35d"
  config.client_secret = "efc9a56b44744cce994bfe099caabb2e"
end

get "/" do
  redirect "/search"
end

get "/connect*:redirect" do
   "<a href=\"/oauth/connect#{params[:redirect]}\">Connect with Instagram</a>"
end

get "/oauth/connect*" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback*" do
  response_insta = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response_insta.access_token
  session[:user] = response_insta.user.username
  session[:user_photo] = response_insta.user.profile_picture
  session['instagram_auth'] = "true"
  redirect "/by/"
end

get "/search" do
  if session[:user] 
    @current_user = session[:user]
  else
    @current_user = "<a href=\"/oauth/connect\">Connect with Instagram</a>"
  end
  @media_items = []
  @location = Geokit::Geocoders::YahooGeocoder.geocode "67.175.7.149" #"#{request_i}"
  @media_items = Instagram.media_search(@location.lat, @location.lng)
  haml :address  
end

post "/search" do
  @media_items = []
  @location = Geokit::Geocoders::YahooGeocoder.geocode "#{params[:address]}"
  @media_items = Instagram.media_search(@location.lat, @location.lng)
  haml :search_results
end

get "/by/:name" do
  unless session['instagram_auth'] == "true"
    redirect "/connect&user=#{params[:name]}"
  end
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user
  user_search = Instagram.user_search(params[:name])
  user_id = user_search.map {|get| get.id}
  html =""
  @media_feed = Instagram.user_recent_media(user_id[0].to_i, :access_token => session[:access_token])
  @media_feed.map do |media|
    html << "<img src='#{media.images.thumbnail.url}'>"
  end
  html
end

get "/*" do
  redirect "/"
end
