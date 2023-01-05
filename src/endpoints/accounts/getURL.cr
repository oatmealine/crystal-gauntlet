require "uri"
require "compress/gzip"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getAccountURL.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  "#{config_get("general.hostname").as(String)}/#{config_get("general.append_path").as(String)[0..-2]}"
}
