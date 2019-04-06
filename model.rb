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
    return db.execute("SELECT PizzaName, Price, Id FROM pizzas")
end

def cart(id)
    db = database()
    return db.execute("SELECT PizzaName, Price, PizzaId FROM pizzas INNER JOIN carts ON UserId = #{id} WHERE PizzaId = Id")
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
    invoiceid = db.execute("SELECT Id FROM invoices WHERE Timestamp = '#{time}'")
    cart.each do |item|
        print item
        db.execute("INSERT INTO pizza_invoice_relation (InvoiceId, PizzaId) VALUES (?, ?)", invoiceid, item[2])
    end
    delete_cart(id)
end

def delete_cart(id)
    db = database()
    db.execute("DELETE FROM carts WHERE UserId = #{id}")
end

def occurs(indata)
    i = 0
    pizzas = Hash.new 0
    pizza_output = []
    while i < indata.length
        if indata[i+1] != nil && indata[i][5] == indata[i+1][5] 
            pizzas[indata[i][0]] += 1
        else
            pizzas[indata[i][0]] += 1
            pizza_output << pizzas
            pizzas = Hash.new 0
        end
        i += 1
    end

    i = 0
    prices = Hash.new 0
    prices_output = []
    while i < indata.length
        if indata[i+1] != nil && indata[i][5] == indata[i+1][5] 
            prices[indata[i][2]] += 1
        else
            prices[indata[i][2]] += 1
            prices_output << prices
            prices = Hash.new 0
        end
        i += 1
    end

    i = 0
    sums = []
    while i < indata.length
        if indata[i+1] != nil && indata[i][5] != indata[i+1][5]
            sums << indata[i][3]
        end
        i += 1
    end
    sums << indata[i-1][3]

    i = 0
    timestamps = []
    while i < indata.length
        if indata[i+1] != nil && indata[i][5] != indata[i+1][5]
            timestamps << indata[i][4]
        end
        i += 1
    end
    timestamps << indata[i-1][4]

    name = []
    timestamps.length.times do
        name << indata.first[1]
    end

    return pizza_output, prices_output, sums, timestamps, name
end

def invoice(id)
    db = database()
    data = (db.execute("SELECT PizzaName, Name, Price, Sum, Timestamp, InvoiceId
    FROM invoices 
    INNER JOIN pizza_invoice_relation 
    INNER JOIN pizzas 
    INNER JOIN users ON invoices.UserId = #{id}
    WHERE pizza_invoice_relation.PizzaId = pizzas.Id 
    AND users.Id = invoices.UserId 
	AND pizza_invoice_relation.InvoiceId = invoices.Id
    ORDER BY Timestamp
    "))
    return occurs(data)
end