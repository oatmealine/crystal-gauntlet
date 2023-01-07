require "uri"

include CrystalGauntlet

comments_per_page = 10

CrystalGauntlet.endpoints["/getGJComments21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  level_id = params["levelID"].to_i

  comment_offset = (params["page"]? || "0").to_i * comments_per_page

  amount = DATABASE.scalar("select count(*) from comments where level_id = ?", level_id)

  # todo: handle binaryVersion < 32

  comments_str = [] of String
  users_str = [] of String
  has_users_str = false

  DATABASE.query("select comments.id, comment, comments.created_at, likes, percent, user_id, users.username, users.udid, users.account_id, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special from comments left join users on users.id == user_id where level_id = ? order by #{params["mode"]? == 1 ? "likes" : "comments.created_at"} desc limit #{comments_per_page} offset #{comment_offset}", level_id) do |rs|
    rs.each do
      id = rs.read(Int32)
      comment = rs.read(String)
      created_at = rs.read(String)
      likes = rs.read(Int32)
      percent = rs.read(Int32 | Nil)
      user_id = rs.read(Int32)
      username = rs.read(String | Nil)
      udid = rs.read(String | Nil)
      account_id = rs.read(Int32 | Nil)
      icon_type = rs.read(Int32)
      color1 = rs.read(Int32)
      color2 = rs.read(Int32)

      icon_value = [rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32)][icon_type]

      special = rs.read(Int32)

      if params["binaryVersion"].to_i32 > 31
        comments_str << [
          Format.fmt_comment({
            2 => Base64.urlsafe_encode(comment),
            3 => user_id,
            4 => likes,
            5 => 0,
            6 => id,
            7 => likes <= config_get("comments.spam_thres", -3_i64),
            8 => account_id,
            9 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
            10 => percent || 0,
            11 => "0",
            12 => "0,0,0", # todo: badge
          }),
          Format.fmt_comment({
            1 => username || "-",
            9 => icon_value,
            10 => color1,
            11 => color2,
            14 => icon_type,
            15 => special,
            16 => account_id || udid
          })
        ].join(":")
      else
        comments_str << Format.fmt_comment({
          2 => Base64.urlsafe_encode(comment),
          3 => user_id,
          4 => likes,
          5 => 0,
          6 => id,
          7 => likes <= config_get("comments.spam_thres", -3_i64),
          8 => account_id,
          9 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
          10 => percent || 0,
          11 => "0",
          12 => "0,0,0", # todo: badge
        })

        users_str << [user_id, username || "-", account_id || udid ].join(":")
        has_users_str = true
      end
    end
  end

  search_meta = "#{amount}:#{comment_offset}:#{comments_per_page}"

  if has_users_str
    [comments_str.join("|"), users_str.join("|"), search_meta].join("#")
  else
    [comments_str.join("|"), search_meta].join("#")
  end
}

CrystalGauntlet.endpoints["/getGJComments20.php"] = CrystalGauntlet.endpoints["/getGJComments21.php"]
