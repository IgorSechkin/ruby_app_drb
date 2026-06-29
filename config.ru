require 'rack'
require 'rubygems'
require 'bundler'
require './app'
use Rack::Reloader

# Собираем приложение с помощью Rack::Builder
app = Rack::Builder.new do
  map "/" do
    run App.new
  end

end

run app
