require "http/server"
require "uri"
require "sqlite3"
require "migrate"
require "dotenv"

require "./enums"
require "./hash"
require "./format"
require "./accounts"
require "./gjp"

Dotenv.load

module CrystalGauntlet
  VERSION = "0.1.0"

  APPEND_PATH = "asdfasdfasd/"
  DATABASE = DB.open(ENV["DATABASE_URL"])

  @@endpoints = Hash(String, (String -> String)).new

  def self.endpoints
    @@endpoints
  end

  def self.run()
    server = HTTP::Server.new do |context|
      # expunge trailing slashes
      path = context.request.path.chomp("/")

      path = path.sub(APPEND_PATH, "")
      body = context.request.body

      if !body
        puts "no body :("
      elsif @@endpoints.has_key?(path)
        func = @@endpoints[path]
        value = func.call(body.gets_to_end)
        context.response.content_type = "text/plain"
        context.response.print value
        puts "#{path} -> #{value}"
      else
        context.response.respond_with_status(404, "endpoint not found")
        puts "#{path} -> 404"
      end
    end

    puts "Listening on http://127.0.0.1:8080"
    server.listen(8080)
  end
end

require "./endpoints/**"

CrystalGauntlet.run()
