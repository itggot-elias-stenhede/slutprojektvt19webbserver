require 'sinatra'
require 'slim'
enable :sessions
require_relative './model.rb'
include MyModule

helpers do
    #Returns true or false depending if user is logged in
    #
    def permission()
        if session[:loggedin]
            return true
        else
            return false
        end
    end    
    #Returns currently logged in user's id
    #
    def id()
        return session[:userdata][1]
    end
end


# Displays homepage differently depending if user is logged in or not
#
get ("/") do
    if permission()
        slim(:profile)
    else
        slim(:home)
    end
end

# Displays the menu
#
get ("/menu") do
    pizzas()
    slim(:menu, locals: {pizzas: pizzas()})
end

# Displays info page
#
get ("/info") do
    slim(:info)
end

# Displays a register form
#
get ("/register") do
    slim(:register)
end

# Displays a login form
#
get ("/login") do
    slim(:login)
end

# Displays a page telling user to log in
#
get ("/permission") do
    slim(:permission)
end

# Displays a profile page
#
get ("/profile") do
    if permission()
        slim(:profile)
    else
        redirect ("/permission")
    end
end

# Displays a the order page with the avalible pizzas
#
get ("/order") do
    if permission()
        session[:cart] = cart(id())
        slim(:order, locals: {pizzas: pizzas()})
    else
        redirect ("/permission")
    end
end

# Attempts to register a new user and if possible redirects to /login, else displays error message
#
# @param [String] Name, Enter name
# @param [String] Passowrd, Enter password
# @param [String] Phone, Enter phone number
#
# @see model#register
post ("/register") do
    status = register(params)
    if status[:status] == :error
        status[:message]
    else
        redirect("/login")
    end
end

# Attempts login and updates the session
#
# @param [String] Phone, Telefonnummer
# @param [String] Passowrd, Lösenord
#
# @see model#login
post ("/login") do
    status = login(params)
    if status[:status] == :error
        status[:message]
    else
        session[:loggedin] = true
        session[:userdata] = status[:userdata]      #hur skickar jag med användarnamn?
        redirect("/profile")
    end
end

# Adds a pizza to cart
#
# @param [String] Phone, Telefonnummer
#
# @see Model#addtocart
post ("/addtocart") do
    if permission()
        id = id()
        addtocart(params, id)
        redirect ("/order")
    else
        redirect ("/permission")
    end
end

# Creates an order
# 
# @param [String] sum, adds sum to invoice
# @see model#order
post ("/order") do
    if permission()
        id = id()
        order(params, id)
        redirect ("/profile")
    else
        redirect ("/permission")
    end
end

# Shows page with logged in user's invoice
# 
# @param [String] 
# @see model#invoice
get ("/invoices") do
    if permission()
        slim(:invoices, locals: {data: invoice(id())})
    else
        redirect ("/permission")
    end
end

# Destroys session and redirects to homepage
# 
get ("/logout") do
    session.destroy
    redirect("/")
end