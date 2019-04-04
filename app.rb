require 'sinatra'
require 'slim'
enable :sessions
require_relative './model.rb'

helpers do
    def permission()
        if session[:loggedin]
            return true
        else
            return false
        end
    end    
end

get ("/") do
    slim(:home)
end

get ("/menu") do
    slim(:menu)
end

get ("/info") do
    slim(:info)
end

get ("/register") do
    slim(:register)
end

post ("/register") do
    register(params)
    redirect("/profile")
end

get ("/login") do
    slim(:login)
end

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

get ("/permission") do
    slim(:permission)
end

get ("/profile") do
    if permission()
        slim(:profile)
    else
        redirect ("/permission")
    end
end

get ("/order") do
    if permission()
        pizzas = pizzas()
        session[:cart] = cart(session[:userdata][1])
        slim(:order, locals: {pizzas: pizzas})
    else
        redirect ("/permission")
    end
end

post ("/addtocart") do
    id = session[:userdata][1]
    addtocart(params, id)
    redirect ("/order")
end

post ("/order") do
    id = session[:userdata][1]
    order(params, id)
end

get ("/invoices") do
    if permission()
        slim(:invoices)
    else
        redirect ("/permission")
    end
end
