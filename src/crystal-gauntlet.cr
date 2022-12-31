require "http/server"
require "uri"
require "sqlite3"
require "migrate"
require "dotenv"
require "toml"

require "./enums"
require "./lib/hash"
require "./lib/format"
require "./lib/accounts"
require "./lib/gjp"
require "./lib/clean"
require "./lib/songs"

Dotenv.load

module CrystalGauntlet
  VERSION = "0.1.0"

  CONFIG = TOML.parse(File.read("./config.toml"))

  def config_get(key : String)
    this = CONFIG
    key.split(".").each do |val|
      next_val = this.as(Hash)[val]?
      if next_val == nil
        return nil
      else
        this = next_val
      end
    end
    return this
  end

  DATABASE = DB.open(ENV["DATABASE_URL"])

  @@endpoints = Hash(String, (String -> String)).new

  def self.endpoints
    @@endpoints
  end

  def self.run()
    server = HTTP::Server.new do |context|
      # expunge trailing slashes
      path = context.request.path.chomp("/")

      path = path.sub(config_get("general.append_path").as(String | Nil) || "", "")
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

    listen_on = URI.parse(ENV["LISTEN_ON"]? || "http://localhost:8080").normalize

    case listen_on.scheme
    when "http"
      server.bind_tcp(listen_on.hostname.not_nil!, listen_on.port.not_nil!)
    when "unix"
      server.bind_unix(listen_on.to_s.sub("unix://",""))
    end

    puts "Listening on #{listen_on.to_s}"
    server.listen
  end
end

require "./endpoints/**"

CrystalGauntlet.run()
