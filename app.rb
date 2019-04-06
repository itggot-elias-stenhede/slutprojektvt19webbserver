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
    if permission()
        slim(:profile)
    else
        slim(:home)
    end
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

def id()
    return session[:userdata][1]
end

get ("/order") do
    if permission()
        session[:cart] = cart(id())
        slim(:order, locals: {pizzas: pizzas()})
    else
        redirect ("/permission")
    end
end

post ("/addtocart") do
    if permission()
        id = id()
        addtocart(params, id)
        redirect ("/order")
    else
        redirect ("/permission")
    end
end

post ("/order") do
    if permission()
        id = id()
        order(params, id)
        redirect ("/profile")
    else
        redirect ("/permission")
    end
end

get ("/invoices") do
    if permission()
        slim(:invoices, locals: {data: invoice(id())})
    else
        redirect ("/permission")
    end
end
