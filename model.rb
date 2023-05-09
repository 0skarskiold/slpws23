def set_db()
    return SQLite3::Database.new('data/handlaonline.db')
end

def register_user(first_name, last_name, mail,password)
    db = set_db()
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (förnamn,efternamn,mail,lösenord,is_admin) VALUES (?,?,?,?,?)",first_name,last_name,mail,password_digest,0)
end

def login_user(first_name, last_name)
    db = set_db()
    db.results_as_hash = true 
    result = db.execute("SELECT * FROM users WHERE förnamn = ? AND efternamn = ?", first_name, last_name).first
    return result
    
end

def additem(vara_id, antal_vara)
    db = set_db()
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
end

def update_vara(user_id, varunamn, antal_vara)
    db = set_db()
    db.execute("UPDATE anv_varor_relation SET antal = ? WHERE anv_id = ? AND varunamn  = ?", antal_vara, user_id, varunamn)
end

def kundvagn(user_id)
    db = set_db()
    @anv_varor_amount = db.execute("SELECT antal FROM anv_varor_relation WHERE anv_id = ?", user_id)
    @anv_varor = db.execute("SELECT * FROM anv_varor_relation WHERE anv_id = ?", user_id)
end

def delete_vara(user_id, varunamn)
    db = set_db()
    db.execute("DELETE FROM anv_varor_relation WHERE anv_id = ? AND varunamn = ?", user_id, varunamn)
end

def admin()
    db = set_db()
    @list_of_varor = db.execute("SELECT * FROM varor")
end

def varor_new(varunamn, styckpris)
    db = set_db()
    db.execute("INSERT INTO varor (varunamn, pris) VALUES (?, ?)", varunamn, styckpris)
end

def update_varor_admin(gammalt_varunamn, nytt_varunamn, styckpris)
    db = set_db()
    if gammalt_varunamn == nytt_varunamn
        db.execute("UPDATE varor SET pris = ? WHERE varunamn = ?", styckpris, gammalt_varunamn)
    else
        db.execute("UPDATE varor SET pris = ?, varunamn = ? WHERE varunamn = ?", styckpris, nytt_varunamn, gammalt_varunamn)
  end
end

def admindelete(vara_id)
    db = set_db()
    db.execute("DELETE FROM varor WHERE id=?", vara_id)
end