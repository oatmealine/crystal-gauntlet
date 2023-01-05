require "uri"

include CrystalGauntlet

mappacks_per_page = 10

CrystalGauntlet.endpoints["/getGJGauntlets21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  gauntlets = [] of String
  checksum_str = [] of String

  DATABASE.query_all("select id from gauntlets", as: {Int32}).each() do |id|
    levels = DATABASE.query_all("select level_id from gauntlet_links where gauntlet_id = ? order by idx", id, as: {Int32}).join(",")
    gauntlets << Format.fmt_hash({
      1 => id,
      3 => levels
    })
    checksum_str << (id.to_s + levels)
  end

  return gauntlets.join("|") + "#" + Hashes.gen_solo_2(checksum_str.join(""))
}
