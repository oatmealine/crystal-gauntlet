require "http/server"
require "http/server/handler"
require "uri"
require "sqlite3"
require "migrate"
require "dotenv"
require "toml"
require "colorize"

require "./enums"
require "./lib/hash"
require "./lib/format"
require "./lib/accounts"
require "./lib/gjp"
require "./lib/clean"
require "./lib/songs"
require "./lib/ids"

Dotenv.load

module CrystalGauntlet
  VERSION = "0.1.0"

  CONFIG = TOML.parse(File.read("./config.toml"))
  LOG = ::Log.for("crystal-gauntlet")

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

  def severity_color(severity : Log::Severity) : Colorize::Object
    case severity
    when .trace?
      Colorize.with.dark_gray
    when .debug?
      Colorize.with.dark_gray
    when .info?
      Colorize.with.cyan
    when .notice?
      Colorize.with.cyan
    when .warn?
      Colorize.with.yellow
    when .error?
      Colorize.with.red
    when .fatal?
      Colorize.with.light_red
    else
      Colorize.with.white
    end
  end

  struct CrystalGauntletFormat < Log::StaticFormatter
    def run
      Colorize.with.light_gray.dim.surround(@io) do
        timestamp
      end
      string "  "
      severity_color(@entry.severity).surround(@io) do
        @entry.severity.label.rjust(@io, 6)
      end
      string "  "
      Colorize.with.white.surround(@io) do
        source
      end
      string "  "
      message
    end
  end

  class GDHandler
    include HTTP::Handler

    def call(context)
      # expunge trailing slashes
      path = context.request.path.chomp("/")

      path = path.sub(config_get("general.append_path").as(String | Nil) || "", "")

      body = context.request.body

      if CrystalGauntlet.endpoints.has_key?(path) && context.request.method == "POST" && body
        func = CrystalGauntlet.endpoints[path]
        begin
          value = func.call(body.gets_to_end)
        rescue err
          LOG.error { "error while handling #{path}:" }
          LOG.error { err.to_s }
          is_relevant = true
          err.backtrace.each do |str|
            # this is a hack. Oh well
            if str.starts_with?("src/crystal-gauntlet.cr") || (!is_relevant)
              is_relevant = false
            else
              LOG.error {"  #{str}"}
            end
          end
          context.response.content_type = "text/plain"
          context.response.respond_with_status(500, "-1")
        else
          LOG.debug { "-> " + value }
          context.response.content_type = "text/plain"
          context.response.print value
        end
      else
        call_next(context)
      end
    end
  end

  def self.run()
    server = HTTP::Server.new([
      HTTP::LogHandler.new,
      HTTP::StaticFileHandler.new("data/", fallthrough: true, directory_listing: false),
      CrystalGauntlet::GDHandler.new
    ])

    listen_on = URI.parse(ENV["LISTEN_ON"]? || "http://localhost:8080").normalize

    case listen_on.scheme
    when "http"
      server.bind_tcp(listen_on.hostname.not_nil!, listen_on.port.not_nil!)
    when "unix"
      server.bind_unix(listen_on.to_s.sub("unix://",""))
    end

    Log.setup_from_env(backend: Log::IOBackend.new(formatter: CrystalGauntletFormat))

    LOG.notice { "Listening on #{listen_on.to_s}" }
    server.listen
  end
end

require "./endpoints/**"

CrystalGauntlet.run()
