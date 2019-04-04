require 'sqlite3'
require 'bcrypt'

def database()
    return SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
end

def register(params)
    db = database()
    hashed_pass = BCrypt::Password.create("#{params["Password"]}")
    db.execute("INSERT INTO users (Name, Password, Phone) VALUES (?, ?, ?)", params["Name"], hashed_pass, params["Phone"])
end

def login(params)
    db = database()

    if params["Phone"].length > 0
        hashed_pass = db.execute("SELECT Password FROM users WHERE Phone = '#{params["Phone"]}'")
    else
        return {status: :error, message: "Invalid Credentials"}
    end

    if hashed_pass.length == 0
        return {status: :error, message: "Invalid Credentials"}
    else
        hashed_pass = hashed_pass.first.first
    end

    if BCrypt::Password.new(hashed_pass) == params["Password"]
        userdata = db.execute("SELECT Name, Id FROM users WHERE Phone = '#{params["Phone"]}'")
        return {status: :ok, userdata: userdata.first}
    else
        return {status: :error, message: "Invalid Credentials"}
    end
end

def pizzas()
    db = database()
    return db.execute("SELECT Name, Price, Id FROM pizzas")
end

def cart(id)
    db = database()
    return db.execute("SELECT Name, Price, PizzaId FROM pizzas INNER JOIN carts ON UserId = #{id} WHERE PizzaId = Id")
end

def addtocart(params, id)
    db = database()
    db.execute("INSERT INTO carts (UserId, PizzaId) VALUES (?, ?)", id, params["pizza-id"])
end

def order(params, id)
    db = database()
    cart = cart(id)
    i = 0
    time = Time.now.to_s[0..18]
    db.execute("INSERT INTO invoices (Sum, UserId, Timestamp) VALUES (?, ?, ?)", params["sum"].to_i, id, time)
    cart.each do |item|
        db.execute("INSERT INTO pizza_invoice_relation (InvoiceId, PizzaId) VALUES (?, ?)", id, item[2])       #probleeeem
    end
end