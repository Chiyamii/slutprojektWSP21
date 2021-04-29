require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
enable :sessions


get('/') do
    slim(:index)
end 

get('/error') do
    "<h1>Something went wrong</h1>"
end
  
get('/items') do
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM items")
    slim(:"items/index",locals:{items:result})
end

get('/items/new') do
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM categories")
    slim(:"items/new",locals:{categories:result})
end

post('/items/new') do
    item_name = params[:item_name]
    stock = params[:stock].to_i
    price = params[:price].to_i
    if params[:image] && params[:image][:filename]
        filename = params[:image][:filename]
        file = params[:image][:tempfile]
        path = "./public/img/#{filename}"
        File.open(path, 'wb') do |f|
            f.write(file.read)
        end
        path = "img/#{filename}"
    end
    description = params[:description]
    db = SQLite3::Database.new("db/webshop.db")
    db.execute("INSERT INTO items (name,stock,price,image,description) VALUES (?,?,?,?,?)",item_name,stock,price,path,description)
    
    #Lägger in i många till många-tabellen
    category = params[:cat]
    id_category = db.execute("SELECT * FROM categories WHERE category = ?",category).first
    p id_category
    item_id = db.execute("SELECT id FROM items ORDER BY id DESC LIMIT 1").first
    p item_id
    db.execute("INSERT INTO categories_items_relation (item_id,category_id) VALUES (?,?)",item_id[0],id_category[0])
    redirect('/items')
end

post('/items/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/webshop.db")
    db.execute("DELETE FROM items WHERE id = ?", id)
    redirect('/items')
end

post('/items/:id/update') do
    id = params[:id].to_i
    item_name = params[:item_name]
    stock = params[:stock].to_i
    price = params[:price].to_i
    description = params[:description]
    db = SQLite3::Database.new("db/webshop.db")
    db.execute("UPDATE items SET name = ?,stock = ?,price = ?,description = ? WHERE id = ?",item_name,stock,price,description,id)
    redirect('/items')
end

post('/items/:id/add_item') do
    item_count = params[:item_count]
    id = params[:id].to_i
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM items WHERE id = ?", id).first  
    p result  
    db.execute("INSERT INTO cart (user_id,item_id,item_count) VALUES (?,?,?)",session[:id],result["id"],item_count)
    redirect('/items')
end

get('/items/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM items WHERE id = ?", id).first
    result2 = db.execute("SELECT * FROM categories")
    slim(:"/items/edit", locals:{result:result,categories:result2})
end
  
get('/items/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM items WHERE id = ?",id).first
    #result2 = db.execute("SELECT Name FROM artists WHERE ArtistId = ?",id).first
    slim(:"items/show",locals:{result:result})
end


get('/cart') do
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM cart WHERE user_id = ?",session[:id])
    p result
    result2 = []
    result.each do |item|
        result2 << db.execute("SELECT * FROM items WHERE id = ?",item['item_id'])
    end
    p result2
    slim(:"cart/index",locals:{cart:result,items:result2})
end



get('/login') do
    slim(:"users/login")
end
  
get('/register') do
    slim(:"users/register")
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    adress = params[:adress]

    db = SQLite3::Database.new("db/webshop.db")
    result = db.execute("SELECT id FROM users WHERE username=?", username)
  
    if result.empty?
      if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        p password_digest
        db.execute("INSERT INTO users (username,password_digest,adress) VALUES (?,?,?)",username,password_digest,adress)
        redirect('/login')
      else
        "<a href='/register'>Passwords didn't match. Try again</a>"
      end
    else
        "<a href='/register'>Username already exists. Try again</a>"
    end
end
  
post('/login') do
    username = params[:username]
    password = params[:password]
  
    db = SQLite3::Database.new("db/webshop.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username=?", username).first
    password_digest = result["password_digest"]
    id = result["id"]
    
    if BCrypt::Password.new(password_digest) == password
      session[:id] = id
      redirect('/items')
    else
        "<a href='/login'>Wrong password or username. Try again</a>"
    end
end



# get('/') do     
#     slim(:index)
# end

# get('/shop/:id') do      
#     params[”id”]
# end

# error 404 do      
#     "<h1>Something went bad</h1>"
# end
# post('/login') do     
#     user_id = params[:id].to_i
#     db = SQLite3::Database.new("db/database.db")   
#     db.results_as_hash = true   
#     result = db.execute("SELECT * FROM users WHERE id = ?",user_id)     
#     name = params[:firstname]     
#     redirect('/index')
# end
# #locals:{}