require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

mappacks_per_page = 10

CrystalGauntlet.endpoints["/getGJMapPacks21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  page = params["page"].to_i32
  map_pack_hash = Hash(Int32, Hash(String, String)).new
  levels = Hash(Int32, Array(Int32)).new

  DATABASE.query_each("select map_packs.id, map_packs.name, map_packs.stars, map_packs.coins, map_packs.difficulty, map_packs.col1, map_packs.col2, map_pack_links.level_id from map_packs join map_pack_links on map_packs.id = map_pack_links.mappack_id order by map_packs.id, map_pack_links.idx") do |rs|
    id = rs.read(Int32)
    name = rs.read(String)
    stars = rs.read(Int32)
    coins = rs.read(Int32)
    difficulty = rs.read(Int32)
    col1 = rs.read(String)
    col2 = rs.read(String | Nil)
    level_id = rs.read(Int32)

    if !col2
      col2 = col1
    end

    if !map_pack_hash.has_key?(id)
      map_pack_hash[id] = {
        "name" => name,
        "stars" => stars.to_s,
        "coins" => coins.to_s,
        "difficulty" => difficulty.to_s,
        "col1" => col1,
        "col2" => col2
      }
    end

    if !levels.has_key?(id)
      levels[id] = [ level_id ]
    else
      levels[id] << level_id
    end
  end

  map_packs = [] of String
  hash_data = [] of Tuple(Int32, Int32, Int32)

  min_idx = page * mappacks_per_page
  max_idx = min_idx + mappacks_per_page - 1

  #"1:".$mappack["ID"].":2:".$mappack["name"].":3:".$mappack["levels"].":4:".$mappack["stars"].":5:".$mappack["coins"].":6:".$mappack["difficulty"].":7:".$mappack["rgbcolors"].":8:".$colors2."|";
  idx = 0
  map_pack_hash.each_key do |id|
    if idx >= min_idx && idx <= max_idx
      map_packs << Format.fmt_hash({
        1 => id,
        2 => map_pack_hash[id]["name"],
        3 => levels[id].join(","),
        4 => map_pack_hash[id]["stars"],
        5 => map_pack_hash[id]["coins"],
        6 => map_pack_hash[id]["difficulty"],
        7 => map_pack_hash[id]["col1"],
        8 => map_pack_hash[id]["col2"]
      })

      hash_data << { id, map_pack_hash[id]["stars"].to_i32, map_pack_hash[id]["coins"].to_i32 }
    end

    idx += 1
  end

  total_count = DATABASE.scalar "select count(*) from map_packs"

  [map_packs.join("|"), "#{total_count}:#{page * mappacks_per_page}:#{mappacks_per_page}", Hashes.gen_pack(hash_data) ].join("#")
}

CrystalGauntlet.endpoints["/getGJMapPacks20.php"] = CrystalGauntlet.endpoints["/getGJMapPacks21.php"]
CrystalGauntlet.endpoints["/getGJMapPacks.php"] = CrystalGauntlet.endpoints["/getGJMapPacks21.php"]
