require 'sinatra'
require 'slim'
require 'sqlite3'


enable :sessions


get('/')  do
    
    db = SQLite3::Database.new("db/handlaonline.db")
    db.results_as_hash = true
    result = db.execute("SELECT pris FROM varor WHERE id=?", 1)
    
    p result
    slim(:start)
end 

