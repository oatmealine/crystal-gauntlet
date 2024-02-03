require "athena-routing"

module CrystalGauntlet::Server
  class GDHandler
    include HTTP::Handler

    def call(context : HTTP::Server::Context)
      # expunge trailing slashes
      path = context.request.path.chomp("/")
      # remove slashes at the beginning of the path, if there are more than one
      path = path.sub(/^\/*(?!\/)/, "/")

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
          context.response.respond_with_status(500, "uh oh!!! server did a fucky wucky")
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

  def self.run()
    template_handler = ART::RoutingHandler.new

    CrystalGauntlet.template_endpoints.each do |key, handler|
      template_handler.add(
        key[:name],
        ART::Route.new(
          key[:path],
          methods: key[:methods]
        )
      ) { |ctx, params| handler.call(ctx, params) }
    end

    server = HTTP::Server.new([
      HTTP::LogHandler.new,
      HTTP::StaticFileHandler.new("public/", fallthrough: true, directory_listing: false),
      HTTP::StaticFileHandler.new((DATA_FOLDER / "songs").to_s, fallthrough: true, directory_listing: false),
      GDHandler.new,
      template_handler.compile
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
    Ranks.init()

    @@up_at = Time.utc
    LOG.notice { "Listening on #{listen_on.to_s.colorize(:white)}" }
    server.listen
  end
end
