require './lib/guillotine'

=begin   #basic syntax for running the app
module MyApp
  class App < Guillotine::App
    adapter = Guillotine::Adapters::MemoryAdapter.new
    set :service => Guillotine::Service.new(adapter)

    get '/' do
      redirect 'https://homepage.com'
    end
  end
end
=end

#require 'guillotine'

require 'fdb'
$URL = "http://localhost:4567/" ##updating base_url
module MyApp
  class App < Guillotine::App
    set :root, File.dirname(__FILE__)
    set :views, File.dirname(__FILE__) + '/views'
  	FDB.api_version 200
  	db = FDB.open
    adapter = Guillotine::FDBAdapter.new(db)

    options =  {
      "default_url" => 'https://foundationdb.com'
    }

    set :service => Guillotine::Service.new(adapter, options)
    get '/' do
  #    redirect 'http://foundationdb.com'
      erb :index ###for the web UI
    end
    post '/' do
	    temp = params[:message]
	    if /http(s)?:\/\//.match(temp).nil? ###updating regex match
		    temp = "http://" + temp
	    end
        
	    "your link: #{$URL}#{adapter.add(temp)}" #link that is returned to the user
    end
    get '/admin' do
	    @adapt = adapter
        @links = adapter.get_key_hash(db) #returns a hash with URLcode => [counter,time created] 
	    puts
	    erb :admin
    end
    post '/admin' do
	    adapter.delete_code(params[:message])
	    redirect '/admin' 
    end	    
  end
end

