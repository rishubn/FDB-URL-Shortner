require "rubygems"
use Rack::Static, :urls => ['/stylesheets', '/javascripts'], :root => 'public'
require File.expand_path("../app.rb", __FILE__)
run MyApp::App
