def connect_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def login(username, password)
    db = connect_db("db/webshop.db")

    result = db.execute("SELECT * FROM users WHERE username=?", username).first
    
    if result != nil
        password_digest = result["password_digest"]
        id = result["id"]
        if BCrypt::Password.new(password_digest) == password
        session[:id] = id
        redirect('/items')
        else
            "<a href='/login'>Wrong password or username. Try again</a>"
        end
    else
        "<a href='/login'>Wrong password or username. Try again</a>"
    end
end

def register(username, password, password_confirm, adress)
    db = connect_db("db/webshop.db")
    
    result = db.execute("SELECT id FROM users WHERE username=?", username)
  
    if result.empty?
      if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username,password_digest,adress) VALUES (?,?,?)",username,password_digest,adress)
        redirect('/login')
      else
        "<a href='/register'>Passwords didn't match. Try again</a>"
      end
    else
        "<a href='/register'>Username already exists. Try again</a>"
    end
end