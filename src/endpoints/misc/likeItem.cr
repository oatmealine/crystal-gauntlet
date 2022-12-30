require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/likeGJItem211.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  if !params.has_key?("itemID")
    return "-1"
  end

  item_id = params["itemID"].to_i

  type = 1
  if params.has_key?("type")
    type = params["type"].to_i
  end

  table = ""
  column = ""
  case type
  when 1
    table = "levels"
    column = "id"
  else # type 2 = comment, type 3 = account comments
    return "-1"
  end

  is_like = 1
  if params.has_key?("isLike")
    is_like = params["isLike"]
  end

  sign = is_like == 1 ? '+' : '-'
  
  # note: formatting them like this is not a security vulnerability as the only possibilities for table, sign
  # and column are already known and not controlled directly by user input
  DATABASE.exec "update #{table} set likes = likes #{sign} 1 where #{column} = ?", item_id
  "1"
}
