require 'sqlite3'
require 'bcrypt'

module MyModule
    #Returns the database
    #
    def database()
        return SQLite3::Database.new("db/database.db")
    end

    # Attempts to register user
    #
    # @param [String] params phone
    # @param [String] params password
    # @param [String] params name
    #
    # @return [Hash]
    #   * :status [Symbol] whether an error occured (:ok or :error)
    #   * :message [String] the error message
    def register(params)
        db = database()
        if params["Name"].length < 2
            return {status: :error, message: "Name has to be longer than 3 characters!"}
        elsif params["Password"].length < 5
            return {status: :error, message: "Password needs to contain 6 or more characters!"}
        end
        
        if db.execute("SELECT Phone FROM users WHERE Phone = #{params["Phone"]}") == []
            hashed_pass = BCrypt::Password.create("#{params["Password"]}")
            db.execute("INSERT INTO users (Name, Password, Phone) VALUES (?, ?, ?)", params["Name"], hashed_pass, params["Phone"])
            return {status: :ok}
        else
            return {status: :error, message: "Phone number is already in use"}
        end
    end

    # Attempts to login
    #
    # @param [String] params phone
    # @param [String] params password
    #
    # @return [Hash]
    #   * :status [Symbol] whether an error occured (:ok or :error)
    #   * :message [String] the error message
    def login(params)
        db = database()
        if params["Phone"].length > 0
            hashed_pass = db.execute("SELECT Password FROM users WHERE Phone = ?", params["Phone"])
        else
            return {status: :error, message: "Invalid Credentials"}
        end

        if hashed_pass.length == 0
            return {status: :error, message: "Invalid Credentials"}
        else
            hashed_pass = hashed_pass.first.first
        end

        if BCrypt::Password.new(hashed_pass) == params["Password"]
            userdata = db.execute("SELECT Name, Id FROM users WHERE Phone = ?", params["Phone"])
            return {status: :ok, userdata: userdata.first}
        else
            return {status: :error, message: "Invalid Credentials"}
        end
    end

    # Fetches pizzas
    #
    # @return [Array]
    #   PizzaName, Price, PizzaId
    def pizzas()
        db = database()
        return db.execute("SELECT PizzaName, Price, Id FROM pizzas")
    end

    # Fetches content in cart
    #
    # @param [Integer] User Id
    #
    # @return [Array]
    #   PizzaName, Price, PizzaId
    def cart(id)
        db = database()
        return db.execute("SELECT PizzaName, Price, PizzaId FROM pizzas INNER JOIN carts ON UserId = ? WHERE PizzaId = Id", id)
    end

    # Adds pizza to cart in database
    #
    # @param [Integer] User Id
    # @param [Integer] Pizza Id
    def addtocart(params, id)
        db = database()
        db.execute("INSERT INTO carts (UserId, PizzaId) VALUES (?, ?)", id, params["pizza-id"])
    end

    # Adds all pizzas in cart to an invoice calls the function delete_cart
    #
    # @param [String] Sum
    def order(params, id)
        db = database()
        cart = cart(id)
        i = 0
        time = Time.now.to_s[0..18]
        db.execute("INSERT INTO invoices (Sum, UserId, Timestamp) VALUES (?, ?, ?)", params["sum"].to_i, id, time)
        invoiceid = db.execute("SELECT Id FROM invoices WHERE Timestamp = ?", time)
        cart.each do |item|
            print item
            db.execute("INSERT INTO pizza_invoice_relation (InvoiceId, PizzaId) VALUES (?, ?)", invoiceid, item[2])
        end
        delete_cart(id)
    end

    # Delete all id's from specific user's cart
    #
    # @param [String] UserId
    def delete_cart(id)
        db = database()
        db.execute("DELETE FROM carts WHERE UserId = ?", id)
    end

    # Fetches and returns a error message
    #
    # @return [String] error message
    def get_error()
        error = session[:message]
        session.destroy  
        return error
    end

    # Rearranges raw data from database to a more structured format
    #
    # @param [String] PizzaName
    # @param [String] Name
    # @param [String] Price
    # @param [String] Sum
    # @param [String] Timestamp
    # @param [String] InvoiceId
    # @return [Array]
        # @return [Hash]
            # pizza_output
        # @return [Hash]
            # prices_output
        # @return [Array]
            # sums
        # @return [Array]
            # timestamps
        # @return [Array]
            # name
    def occurs(indata)
        i = 0
        pizzas = Hash.new 0
        prices = Hash.new 0
        pizza_output = []
        prices_output = []
        sums = []
        timestamps = []
        name = []
        while i < indata.length
            if indata[i+1] != nil && indata[i][5] == indata[i+1][5] 
                pizzas[indata[i][0]] += 1
                prices[indata[i][2]] += 1
            else
                pizzas[indata[i][0]] += 1
                pizza_output << pizzas
                pizzas = Hash.new 0
                prices[indata[i][2]] += 1
                prices_output << prices
                prices = Hash.new 0
                name << indata.first[1]
                sums << indata[i][3]
                timestamps << indata[i][4]
            end
            i += 1
        end
        if indata[i-1] != nil
            sums << indata[i-1][3]
            timestamps << indata[i-1][4]
        end
        return pizza_output, prices_output, sums, timestamps, name
    end

    # Fetches data from database
    #
    def invoice(id)
        db = database()
        data = (db.execute("SELECT PizzaName, Name, Price, Sum, Timestamp, InvoiceId
        FROM invoices 
        INNER JOIN pizza_invoice_relation 
        INNER JOIN pizzas 
        INNER JOIN users ON invoices.UserId = ?
        WHERE pizza_invoice_relation.PizzaId = pizzas.Id 
        AND users.Id = invoices.UserId 
        AND pizza_invoice_relation.InvoiceId = invoices.Id
        ORDER BY Timestamp
        ", id))
        return occurs(data)
    end
end