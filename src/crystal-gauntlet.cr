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
require "./lib/xor"
require "./lib/accounts"
require "./lib/gjp"
require "./lib/clean"
require "./lib/songs"
require "./lib/ids"
require "./lib/level"
require "./lib/dailies"
require "./lib/templates"
require "./lib/reupload"
require "./lib/creator_points"
require "./lib/versions"
require "./lib/ips"

require "./patch-exe.cr"

if File.exists?(".env")
  Dotenv.load
end

include CrystalGauntlet::PatchExe

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
  def config_get(key : String, default)
    config_get(key).as?(typeof(default)) || default
  end

  DATABASE = DB.open(ENV["DATABASE_URL"]? || "sqlite3://./crystal-gauntlet.db")

  # todo: unhardcore
  DATA_FOLDER = Path.new("data")

  @@endpoints = Hash(String, (HTTP::Server::Context -> String)).new
  @@template_endpoints = Hash(String, (HTTP::Server::Context -> Nil)).new

  @@up_at = nil

  def self.uptime
    if !@@up_at
      return Time::Span::ZERO
    else
      return Time.utc - @@up_at.not_nil!
    end
  end

  def self.uptime_s
    span = uptime
    Format.fmt_timespan_long(span)
  end

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
          max_size = 2048

          value_displayed = value
          if value.size > max_size
            value_displayed = value[0..max_size] + ("…".colorize(:dark_gray).to_s)
          end
          LOG.debug { "-> ".colorize(:green).to_s + value_displayed }

          context.response.content_type = "text/plain"
          # to let endpoints manually write to IO
          if value != ""
            context.response.print value
          end
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
          func.call(context)
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
        end
      else
        call_next(context)
      end
    end
  end

  def self.run()
    Log.setup_from_env(backend: Log::IOBackend.new(formatter: CrystalGauntletFormat))

    migrate = false
    calc_creator_points = false
    patch_exe = false
    patch_exe_location = nil

    parser = OptionParser.new do |parser|
      parser.banner = "Usage: crystal-gauntlet [command] [arguments]"

      parser.on("migrate", "Migrate the database") do
        migrate = true
        parser.banner = "Usage: crystal-gauntlet migrate [arguments]"
      end
      parser.on("calc_creator_points", "Calculate creator points and update them") do
        calc_creator_points = true
        parser.banner = "Usage: crystal-gauntlet calc_creator_points [arguments]"
      end
      parser.on("patch_exe", "Patch Geometry Dash executables with your server URL (supports #{SUPPORTED_PATCH_PLATFORMS.join(", ")})") do
        patch_exe = true
        parser.banner = "Usage: crystal-gauntlet patch_exe <file>"
        parser.unknown_args do |opt|
          patch_exe_location = opt[0]?
        end
      end
      parser.on("-h", "--help", "Show this help") do
        puts parser
        exit
      end
    end

    parser.parse

    if patch_exe
      if !patch_exe_location
        puts parser
        exit 1
      end
      check_server_length(true)
      LOG.info { "Patching #{patch_exe_location}" }
      patch_exe_file(patch_exe_location.not_nil!)
      exit
    end

    migrator = Migrate::Migrator.new(
      DATABASE
    )

    if migrate
      LOG.info { "Migrating #{ENV["DATABASE_URL"].colorize(:white)}..." }
      migrator.to_latest
      exit
    end

    if calc_creator_points
      LOG.info { "updating creator points" }
      DATABASE.query_all("select id, username, creator_points from users", as: {Int32, String, Int32}).each() do |id, username, old_count|
        new_count = CreatorPoints.update_creator_points id
        if old_count > 0 || new_count > 0
          LOG.info { "#{username}: #{old_count} -> #{new_count}" }
        end
      end

      exit
    end

    if !migrator.latest?
      LOG.fatal { "Database hasn\'t been migrated!! Please run #{"crystal-gauntlet migrate".colorize(:white)}" }
      exit 1
    end

    ["songs", "levels", "saves"].each() { |v|
      Dir.mkdir_p(DATA_FOLDER / v)
    }

    server = HTTP::Server.new([
      HTTP::LogHandler.new,
      HTTP::StaticFileHandler.new("public/", fallthrough: true, directory_listing: false),
      HTTP::StaticFileHandler.new((DATA_FOLDER / "songs").to_s, fallthrough: true, directory_listing: false),
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

    check_server_length(false)

    Reupload.init()

    @@up_at = Time.utc
    LOG.notice { "Listening on #{listen_on.to_s.colorize(:white)}" }
    server.listen
  end
end

require "./endpoints/**"
require "./template_endpoints/**"

CrystalGauntlet.run()
