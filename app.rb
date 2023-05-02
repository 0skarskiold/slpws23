require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions
require_relative 'model.rb'

#Before: KOlla om inloggad/admin


get('/')  do
    #Använder jag db koden någonstans?? kolla
    db = SQLite3::Database.new("data/handlaonline.db")
    @result = db.execute("SELECT * FROM varor")
    if session[:name] == nil
      redirect('/showlogin')
    end
    slim(:index)
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
      register_user(first_name, last_name, mail,password)
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
  result = login_user(first_name, last_name)
  pwdigest = result["lösenord"]
  if BCrypt::Password.new(pwdigest) == password
    name = result["förnamn"]
    session[:name] = name
    session[:user_id] = result["id"]
    session[:is_admin] = result["is_admin"]
    redirect('/')
  else
    session[:felmeddelande] = "Fel lösenord"
    session[:go_back] = "/showlogin"
    slim(:felmeddelande)
  end
  
end


post('/additem/:vara_id') do
  vara_id = params[:vara_id] 
  antal_vara = params[:antal]
  additem(vara_id, antal_vara)
  redirect('/')
end


post('/varor/:varunamn/update') do 
  user_id = session[:user_id]
  varunamn = params[:varunamn]
  antal_vara = params[:antal]
  update_vara(user_id, varunamn, antal_vara)
  redirect('/kundvagn')
end

get('/kundvagn') do
  kundvagn(session[:user_id])
  session[:varor] = @anv_varor
  session[:antal_varor] = @anv_varor_amount
  slim(:kundvagn)
end

post('/varor/:varunamn/delete') do
  delete_vara(session[:user_id], params[:varunamn])
  redirect('/kundvagn')
end

get('/admin') do 
  if session[:is_admin] == 1 
    admin()
    slim(:admin)
  else
    redirect('/')
  end
end

post('/varor/new') do
  varor_new(params[:nytt_varunamn], params[:styckpris])
  redirect('/')
end

post('/varor/:varunamn/update') do 
  nytt_varunamn = params[:nytt_varunamn]
  gammalt_varunamn = params[:varunamn]
  styckpris = params[:styckpris]
  db = SQLite3::Database.new('data/handlaonline.db')
  if gammalt_varunamn == nytt_varunamn
    db.execute("UPDATE varor SET pris = ? WHERE varunamn = ?", styckpris, gammalt_varunamn)
  else
    db.execute("UPDATE varor SET pris = ?, varunamn = ? WHERE varunamn = ?", styckpris, nytt_varunamn, gammalt_varunamn)
  end
  redirect('/')
end

post('/admindelete/:vara_id') do
  #Kolla om admin skickar 
  db = SQLite3::Database.new('data/handlaonline.db')
  vara_id = params[:vara_id]
  db.execute("DELETE FROM varor WHERE id=?", vara_id)
  redirect('/admin')
end