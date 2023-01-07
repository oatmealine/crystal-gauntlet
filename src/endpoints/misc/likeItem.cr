require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/likeGJItem211.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

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
    table = "comments"
    column = "id"
  when 3 # account comments
    table = "account_comments"
    column = "id"
  end

  is_like = (params["isLike"]? || "1").to_i
  sign = is_like == 1 ? '+' : '-'

  DATABASE.exec "update #{table} set likes = likes #{sign} 1 where #{column} = ?", item_id
  "1"
}
