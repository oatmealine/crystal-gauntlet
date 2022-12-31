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

  type = (params["type"]? || "1").to_i
  table = ""
  column = ""
  case type
  when 1 # level like
    table = "levels"
    column = "id"
  when 2 # level comment like
    table = "account_comments"
    column = "id"
  when 3 # account comments
    return "-1"
  end

  is_like = (params["isLike"]? || "1").to_i
  sign = is_like == 1 ? '+' : '-'

  # note: formatting them like this is not a security vulnerability as the only possibilities for table, sign
  # and column are already known and not controlled directly by user input
  DATABASE.exec "update #{table} set likes = likes #{sign} 1 where #{column} = ?", item_id
  "1"
}
