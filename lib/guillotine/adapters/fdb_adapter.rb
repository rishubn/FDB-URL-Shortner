

module Guillotine #stores shortened URLs in FDB.

	class FDBAdapter < Adapter
		attr_reader :directory


		#Initializes the adapter for FoundationDB
		def initialize(db, directory=nil)
			#directory within the DB
			@db = db
			@directory = directory
			@keyspace = FDB::Subspace.new(['K'])

		end

		#public functions to store the shortened version of a URL

		#url - the String URL that you're shortening
		#code - an optional String code for the URL
		#options - Optional Guillotine::Service::Options

		#returns the unique String code for the URL. If the URL
		#is added multiple times, this should return the same code.
		def add(url, code=nil, options=nil,timeDel=nil)
			code = get_code(url, code, options)

			@db.transact do |tr|
				existing_url = find(code)
				if existing_url != nil
					raise DuplicateCodeError.new(existing_url, url, code) if url != existing_url
                    
				end

				tr.set(code, url)
				tr.set(url, code)
				#add the code to store the metrics in a separate subspace
                tr[@keyspace[code]['counter']] = [0].pack('q<')
                tr[@keyspace[code]['timestamp']] = [Time.now.to_i].pack('q<')
			end
			code #return the code
		end
		def delete_code(code)
            code = code.encode('binary')
			@db.transact do |tr|
				r = @keyspace[code].range
				tr.clear_range(r[0],r[1])

			end
			clear(find(code))
		
		end

		
		#public function to retrieve the URL for a specific code
		#code - the code to look up the URL
		#returns the URL or nil

		def find(code)
			res = nil
			@db.transact do |tr|
				res = tr.get(code)
			end
			res
		end


		#Public function to retrieve the code for a URL
		#url - the String URL to look up
		# returns the String code or nil
		def code_for(url)
			res = nil
			@db.transact do |tr|
				res = tr.get(url)
			end
			res
		end
        #function in increment the counter atomically
        #code - shortened url code    
		def increment(code)
            code = code.encode('binary')  #Guillotine does not consistently encode the urlcodes with the same encodings. This line enforces binary to avoid duplicate entries
			@db.transact do |tr|
                    tr.add(@keyspace[code]['counter'],[1].pack('q<'))
				end
		end


		#public function to remove the stored short code for the URL
		#url - the String URL to remove
		#returns nil 

		def clear(url)
			@db.transact do |tr|
				tr.clear(url)
				tr.clear(code_for(url))
			end
		end
        #public function that returns a map of the type urlcode => [counter,timestamp]
        #db - database
        #returns map
		def get_key_hash(db)		
			hash = {}
			db.transact do |tr|
				r = @keyspace.range()
				tr.get_range(r[0],r[1]){ |kv|
                    k = FDB::Tuple.unpack(kv.key)[1]
                    v = kv.value.unpack('q<')
                    if hash[k].nil?
                        hash[k] = [v[0]]
                    else
                        hash[k].push(v[0])
                    end
				}
                print hash
                puts
				hash
			end

			
		end

	end

end
