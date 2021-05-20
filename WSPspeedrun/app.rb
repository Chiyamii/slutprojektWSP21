require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'helper.rb'
enable :sessions

before do
    if session[:id] == nil 
        if request.path_info != '/' && request.path_info != '/error' && request.path_info != '/login' && request.path_info != '/register' && request.path_info != '/items'
            session[:error] = "You need to log in to see this"
            redirect('/error')
        end
    else

    end
end
  

get('/error') do
    slim(:error)
end

get('/') do
    slim(:index)
end 

# get('/error') do
#     "<h1>Something went wrong</h1>"
# end
  
get('/items') do
    db = connect_db("db/webshop.db")
    result = db.execute("SELECT * FROM items")
    slim(:"items/index",locals:{items:result})
end

get('/items/new') do
    db = connect_db("db/webshop.db")
    result = db.execute("SELECT * FROM categories")
    slim(:"items/new",locals:{categories:result})
end

post('/items/new') do
    db = connect_db("db/webshop.db")
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
    db.execute("INSERT INTO items (name,stock,price,image,description) VALUES (?,?,?,?,?)",item_name,stock,price,path,description)
    
    #Lägger in i många till många-tabellen
    category = params[:cat]
    id_category = db.execute("SELECT * FROM categories WHERE category = ?",category).first
    item_id = db.execute("SELECT id FROM items ORDER BY id DESC LIMIT 1").first
    db.execute("INSERT INTO categories_items_relation (item_id,category_id) VALUES (?,?)",item_id[0],id_category[0])
    redirect('/items')
end

post('/items/:id/delete') do
    db = connect_db("db/webshop.db")
    id = params[:id].to_i
    db.execute("DELETE FROM items WHERE id = ?", id)
    db.execute("DELETE FROM cart WHERE item_id = ?", id)
    redirect('/items')
end

post('/items/:id/update') do
    db = connect_db("db/webshop.db")
    id = params[:id].to_i
    item_name = params[:item_name]
    stock = params[:stock].to_i
    price = params[:price].to_i
    description = params[:description]
    db.execute("UPDATE items SET name = ?,stock = ?,price = ?,description = ? WHERE id = ?",item_name,stock,price,description,id)
    redirect('/items')
end

post('/items/:id/add_item') do
    db = connect_db("db/webshop.db")
    item_count = params[:item_count]
    id = params[:id].to_i
    result = db.execute("SELECT * FROM items WHERE id = ?", id).first  
    db.execute("INSERT INTO cart (user_id,item_id,item_count) VALUES (?,?,?)",session[:id],result["id"],item_count)
    redirect('/items')
end

get('/items/:id/edit') do
    db = connect_db("db/webshop.db")
    id = params[:id].to_i
    result = db.execute("SELECT * FROM items WHERE id = ?", id).first
    result2 = db.execute("SELECT * FROM categories")
    slim(:"/items/edit", locals:{result:result,categories:result2})
end
  
get('/items/:id') do
    db = connect_db("db/webshop.db")
    id = params[:id].to_i
    result = db.execute("SELECT * FROM items WHERE id = ?",id).first
    #result2 = db.execute("SELECT Name FROM artists WHERE ArtistId = ?",id).first
    slim(:"items/show",locals:{result:result})
end


get('/cart') do
    db = connect_db("db/webshop.db")
    result = db.execute("SELECT * FROM cart WHERE user_id = ?",session[:id])
    result2 = []
    result.each do |item|
        result2 << db.execute("SELECT * FROM items WHERE id = ?",item['item_id'])
    end
    slim(:"cart/index",locals:{cart:result,items:result2})
end

get('/login') do
    slim(:"users/login")
end
  
post('/login') do
    username = params[:username]
    password = params[:password]

    login(username, password)
end

get('/register') do
    slim(:"users/register")
end

post('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    adress = params[:adress]

    register(username, password, password_confirm, adress)
end