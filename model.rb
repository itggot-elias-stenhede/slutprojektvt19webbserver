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

def order(id)
    db = database()
    
end