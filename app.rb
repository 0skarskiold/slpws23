require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions


get('/')  do
    #Använder jag db koden någonstans?? kolla
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
      session[:felmeddelande] = "Lönsenorden matchade inte :("
      session[:go_back] = "/showsignup"
      slim(:felmeddelande)
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
        session[:is_admin] = result["is_admin"]
        redirect('/')
    else
      session[:felmeddelande] = "Fel lösenord"
      session[:go_back] = "/showlogin"
      slim(:felmeddelande)
    end
  
end


#Kan absolut slå ihop detta kodblock med det under
post('/additem/:vara_id') do
  vara_id = params[:vara_id] 
  antal_vara = params[:antal]
  db = SQLite3::Database.new('data/handlaonline.db')
  vara = db.execute("SELECT varunamn FROM varor WHERE id = ?", vara_id)
  pris = db.execute("SELECT pris FROM varor WHERE id = ?", vara_id)
  user_id = session[:user_id]

  #Använder double_check för att kolla om det redan finns varor av samma sort inlagda
  double_check = db.execute("SELECT * FROM anv_varor_relation WHERE anv_id = ? AND varunamn = ?", user_id, vara)

  #KOllar om det finns varor av samma sort inlagda tidigare
  if double_check != [] && antal_vara != ""
    db.execute("UPDATE anv_varor_relation SET antal = ? WHERE varunamn = ? AND anv_id = ?", antal_vara, vara, user_id)
  elsif antal_vara != ""
    db.execute("INSERT INTO anv_varor_relation(anv_id, varunamn, antal, enskilt_pris) VALUES(?, ?, ?, ?)", user_id, vara, antal_vara, pris)  
  end
  

  redirect('/')
end


post('/update_varor/:varunamn') do 
  db = SQLite3::Database.new('data/handlaonline.db')
  user_id = session[:user_id]
  varunamn = params[:varunamn]
  antal_vara = params[:antal]
  db.execute("UPDATE anv_varor_relation SET antal = ? WHERE anv_id = ? AND varunamn  = ?", antal_vara, user_id, varunamn)
  redirect('/kundvagn')
end

get('/kundvagn') do
  db = SQLite3::Database.new('data/handlaonline.db')
  anv_varor_amount = db.execute("SELECT antal FROM anv_varor_relation WHERE anv_id = ?", session[:user_id])
  anv_varor = db.execute("SELECT * FROM anv_varor_relation WHERE anv_id = ?", session[:user_id])
  session[:varor] = anv_varor
  session[:antal_varor] = anv_varor_amount
  slim(:kundvagn)
end

post('/delete/:varunamn') do
  varunamn = params[:varunamn]
  db = SQLite3::Database.new('data/handlaonline.db')
  db.execute("DELETE FROM anv_varor_relation WHERE anv_id = ? AND varunamn = ?", session[:user_id], varunamn)
  redirect('/kundvagn')
end