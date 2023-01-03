require "http/server"
require "http/server/handler"
require "uri"
require "sqlite3"
require "migrate"
require "dotenv"
require "toml"
require "colorize"
require "option_parser"
require "migrate"

require "./enums"
require "./lib/hash"
require "./lib/format"
require "./lib/accounts"
require "./lib/gjp"
require "./lib/clean"
require "./lib/songs"
require "./lib/ids"
require "./lib/level"

if File.exists?(".env")
  Dotenv.load
end

module CrystalGauntlet
  VERSION = "0.1.0"

  CONFIG = File.exists?("./config.toml") ? TOML.parse(File.read("./config.toml")) : TOML.parse("") # todo: log warning?
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

  DATABASE = DB.open(ENV["DATABASE_URL"]? || "sqlite3://./crystal-gauntlet.db")

  @@endpoints = Hash(String, (HTTP::Server::Context -> String)).new
  @@template_endpoints = Hash(String, (HTTP::Server::Context -> String)).new

  def self.endpoints
    @@endpoints
  end

  def self.template_endpoints
    @@template_endpoints
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

    def call(context : HTTP::Server::Context)
      # expunge trailing slashes
      path = context.request.path.chomp("/")

      path = path.sub(config_get("general.append_path").as(String | Nil) || "", "")

      body = context.request.body

      if CrystalGauntlet.endpoints.has_key?(path) && context.request.method == "POST" && body
        func = CrystalGauntlet.endpoints[path]
        begin
          value = func.call(context)
        rescue err
          LOG.error { "error while handling #{path.colorize(:white)}:" }
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

  class TemplateHandler
    include HTTP::Handler

    def call(context : HTTP::Server::Context)
      # expunge trailing slashes
      path = context.request.path.chomp("/")

      body = context.request.body

      if CrystalGauntlet.template_endpoints.has_key?(path)
        func = CrystalGauntlet.template_endpoints[path]
        begin
          value = func.call(context)
        rescue err
          LOG.error { "error while handling #{path.colorize(:white)}:" }
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
          context.response.content_type = "text/html"
          context.response.respond_with_status(500, "Internal server error occurred, sorry about that")
        else
          LOG.debug { "-> " + value }
          context.response.content_type = "text/html"
          context.response.print value
        end
      else
        call_next(context)
      end
    end
  end

  def self.run()
    Log.setup_from_env(backend: Log::IOBackend.new(formatter: CrystalGauntletFormat))

    migrate = false

    parser = OptionParser.new do |parser|
      parser.banner = "Usage: crystal-gauntlet [command] [arguments]"

      parser.on("migrate", "Migrate the database") do
        migrate = true
        parser.banner = "Usage: crystal-gauntlet migrate [arguments]"
      end
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    parser.parse

    if migrate
      LOG.info { "Migrating #{ENV["DATABASE_URL"].colorize(:white)}..." }
      migrator = Migrate::Migrator.new(
        DATABASE
      )
      migrator.to_latest
    else
      server = HTTP::Server.new([
        HTTP::LogHandler.new,
        HTTP::StaticFileHandler.new("data/", fallthrough: true, directory_listing: false),
        CrystalGauntlet::GDHandler.new,
        CrystalGauntlet::TemplateHandler.new
      ])

      listen_on = URI.parse(ENV["LISTEN_ON"]? || "http://localhost:8080").normalize

      case listen_on.scheme
      when "http"
        server.bind_tcp(listen_on.hostname.not_nil!, listen_on.port.not_nil!)
      when "unix"
        server.bind_unix(listen_on.to_s.sub("unix://",""))
      end

      full_server_path = (config_get("general.hostname").as?(String) || "") + "/" + (config_get("general.append_path").as?(String) || "")
      robtop_server_path = "www.boomlings.com/database/"
      if full_server_path.size != robtop_server_path.size
        LOG.warn { "i think you made a mistake? length of full server path and default .exe location do not match" }
        LOG.warn { "  #{full_server_path}" }
        LOG.warn { "  #{robtop_server_path}" }
        min_length = Math.min(full_server_path.size, robtop_server_path.size)
        max_length = Math.max(full_server_path.size, robtop_server_path.size)
        LOG.warn { "  #{" " * min_length}#{"^" * (max_length - min_length)}"}
      end

      LOG.notice { "Listening on #{listen_on.to_s.colorize(:white)}" }
      server.listen
    end
  end
end

require "./endpoints/**"
require "./template_endpoints/**"

CrystalGauntlet.run()
