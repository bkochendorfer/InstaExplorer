require "sinatra"
require "instagram"
require "geokit"
require "haml"

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

Instagram.configure do |config|
  config.client_id = "2512765ae94b4d7a92a413f717b866a3"
  config.client_secret = "d0af45ba66954e298a9cccaead5b1589"
end

get "/" do
  redirect "/oauth/connect"
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)
  session[:access_token] = response.access_token
  redirect "/search"
end

get "/search" do
  haml :address  
end

get "/test" do
  haml :search_results
end

post "/search" do
  @media = []
  @local = []
  @location = Geokit::Geocoders::YahooGeocoder.geocode "#{params[:address]}"
  media_items = Instagram.media_search(@location.lat, @location.lng)
  media_items['data'].map do |media_item|
    @media << "<a href='#{media_item.images.standard_resolution.url}'><img src='#{media_item.images.thumbnail.url}'></a>"
    @local << "#{media_item.location.latitude}, #{media_item.location.longitude}"
  end
  puts @local 
  haml :search_results
end

get "/*" do
  redirect "/"
end
