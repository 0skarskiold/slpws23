require 'sinatra'
require 'slim'
require 'sqlite3'



enable :sessions


get('/')  do
    db = SQLite3::Database.new("data/handlaonline.db")
    @result = db.execute("SELECT * FROM varor")
    slim(:start)
end 

get('/') do
    
end