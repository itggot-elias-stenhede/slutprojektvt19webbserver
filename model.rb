require 'sqlite3'
require 'bcrypt'

def database()
    return SQLite3::Database.new("db/database.db")
end

def register(params)
    db = database()
    hashed_pass = BCrypt::Password.create("#{params["Password"]}")
    db.execute("INSERT INTO users (Name, Password, Phone) VALUES (?, ?, ?)", params["Name"], hashed_pass, params["Phone"])
end