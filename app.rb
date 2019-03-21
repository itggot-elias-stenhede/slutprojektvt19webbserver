require 'sinatra'
require 'slim'
enable :sessions
require_relative './model.rb'

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
    redirect("/login")
end

get ("/login") do
    slim(:login)
end