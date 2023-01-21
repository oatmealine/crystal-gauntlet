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
  else
    return "-1"
  end

  is_like = (params["isLike"]? || "1").to_i
  sign = is_like == 1 ? '+' : '-'

  ip = IPs.get_real_ip(context.request)
  if DATABASE.scalar("select count(*) from ip_actions where action = ? and value = ? and ip = ? limit 1", "like_#{type}", item_id, ip).as?(Int64) == 0
    DATABASE.exec("update #{table} set likes = likes #{sign} 1 where #{column} = ?", item_id)
    DATABASE.exec("insert into ip_actions (action, value, ip) values (?, ?, ?)", "like_#{type}", item_id, ip)

    if type == 1 # level
      likes = DATABASE.scalar("select likes from #{table} where #{column} = ?", item_id).as(Int64)
      if likes == 100
        # notify the creator of 100 likes

        account_id, level_name = DATABASE.query_one("select users.account_id, #{table}.name from #{table} left join users on users.id = #{table}.user_id where #{table}.#{column} = ?", item_id, as: {Int32?, String})
        if account_id
          if DATABASE.scalar("select count(*) from notifications where type = \"like_milestone\" and target = ? and account_id = ?", item_id, account_id).as(Int64) == 0
            Notifications.send_notification(account_id, "like_milestone", item_id, {
              "level_name" => level_name,
              "amount" => likes
            })
          end
        end
      end
    end
  end

  "1"
}

CrystalGauntlet.endpoints["/likeGJItem20.php"] = CrystalGauntlet.endpoints["/likeGJItem211.php"]
CrystalGauntlet.endpoints["/likeGJItem.php"] = CrystalGauntlet.endpoints["/likeGJItem211.php"]

