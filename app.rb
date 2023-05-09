require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions
require_relative 'model.rb'

before("/admin") do 
  if session[:is_admin] != 1
    session[:felmeddelande] = "Du är icke admin"
    session[:go_back] = "/"
    redirect(:fel)
  end 
end

before do
  restricted_paths = ['/kundvagn', '/varor']
  if restricted_paths.include?(request.path_info)
    if session[:user_id] == nil
      session[:felmeddelande] = "Du måste logga in för att få se detta"
      session[:go_back] = "/showlogin"
      redirect(:fel)
    end
  end
end

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
      redirect(:fel)
    end
end

get('/fel') do 
  slim(:felmeddelande)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  first_name = params[:first_name]
  last_name = params[:last_name]
  password = params[:password]
  result = login_user(first_name, last_name)
  if result == nil 
    
    session[:felmeddelande] = "Finns ingen sådan användare"
    session[:go_back] = "/showlogin"
    redirect(:fel)
  else 
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
      redirect(:fel)
    end
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
  redirect('/')
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
  admin()
  slim(:admin)
end

post('/varor/new') do
  varor_new(params[:nytt_varunamn], params[:styckpris])
  redirect('/')
end

post('/varor/:varunamn/adminupdate') do 
  nytt_varunamn = params[:nytt_varunamn]
  gammalt_varunamn = params[:varunamn]
  styckpris = params[:styckpris]
  update_varor_admin(gammalt_varunamn, nytt_varunamn, styckpris)
  redirect('/')
end

post('/admindelete/:vara_id') do
  vara_id = params[:vara_id]
  admindelete(vara_id)
  redirect('/admin')
end