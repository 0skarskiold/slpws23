require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions


get('/')  do
    db = SQLite3::Database.new("data/handlaonline.db")
    @result = db.execute("SELECT * FROM varor")
    if session[:name] == nil
      redirect('/showlogin')
    end
    slim(:start)
end 

get('/showsignup') do
    slim(:signup)
end

post('/signup') do
    first_name = params[:first_name]
    last_name = params[:last_name]
    mail = params[:mail]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('data/handlaonline.db')
      db.execute("INSERT INTO users (förnamn,efternamn,mail,lösenord,is_admin) VALUES (?,?,?,?,?)",first_name,last_name,mail,password_digest,0)
      redirect('/')
    else
      "Lösenorden matchade inte :("
    end
  end

get('/showlogin') do
    slim(:login)
end

post('/login') do
    first_name = params[:first_name]
    last_name = params[:last_name]
    password = params[:password]
    db = SQLite3::Database.new('data/handlaonline.db')
    db.results_as_hash = true 
    result = db.execute("SELECT * FROM users WHERE förnamn = ? AND efternamn = ?", first_name, last_name).first
    pwdigest = result["lösenord"]
    if BCrypt::Password.new(pwdigest) == password
        name = result["förnamn"]
        session[:name] = name
        user_id = result["id"]
        session[:user_id] = user_id
        redirect('/')
    else
      "Fel lösenord"
    end
  
end

post('/additem/:vara_id') do
  vara_id = params[:vara_id] 
  db = SQLite3::Database.new('data/handlaonline.db')
  vara = db.execute("SELECT * FROM varor WHERE id = ?", vara_id)
  user_id = session[:user_id]
   db.execute("INSERT INTO anv_varor_relation(anv_id, varor_id) VALUES(?, ?)", user_id, vara_id) #Detta väljer de saker som finns i båda 

  redirect('/')
end

get('/kundvagn') do
  db = SQLite3::Database.new('data/handlaonline.db')
  anv_varor = db.execute("SELECT varor_id FROM anv_varor_relation WHERE anv_id = ?", session[:user_id])
  session[:varukorg] = anv_varor
  slim(:kundvagn)
end