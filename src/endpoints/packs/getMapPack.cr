require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJMapPacks21.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  page = params["page"].to_i32
  properties = Hash(Int32, Hash(String, String)).new
  levels = Hash(Int32, Array(Int32)).new
  
  DATABASE.query("select map_packs.id, map_packs.name, map_packs.stars, map_packs.coins, map_packs.difficulty, map_packs.col1, map_packs.col2, map_pack_links.level_id from map_packs join map_pack_links on map_packs.id = map_pack_links.mappack_id order by map_pack_links.idx limit 10 offset #{page * 10}") do |rs|
    rs.each do
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

      if !properties.has_key?(id)
        properties[id] = { 
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
  end

  map_packs = [] of String
  hash_data = [] of Tuple(Int32, Int32, Int32)

  #"1:".$mappack["ID"].":2:".$mappack["name"].":3:".$mappack["levels"].":4:".$mappack["stars"].":5:".$mappack["coins"].":6:".$mappack["difficulty"].":7:".$mappack["rgbcolors"].":8:".$colors2."|";
  properties.each_key do |id|
    map_packs << Format.fmt_hash({
      1 => id,
      2 => properties[id]["name"],
      3 => levels[id].join(","),
      4 => properties[id]["stars"],
      5 => properties[id]["coins"],
      6 => properties[id]["difficulty"],
      7 => properties[id]["col1"],
      8 => properties[id]["col2"]
    })

    hash_data << { id, properties[id]["stars"].to_i32, properties[id]["coins"].to_i32 }
  end

  total_count = DATABASE.scalar "select count(*) from map_packs"

  [map_packs.join("|"), "#{total_count}:#{page * 10}:10", Hashes.gen_pack(hash_data) ].join("#")
}
