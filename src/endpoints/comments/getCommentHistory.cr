require "uri"

include CrystalGauntlet

comments_per_page = 10

CrystalGauntlet.endpoints["/getGJCommentHistory.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  comment_status, target_account_id = DATABASE.query_one("select comments_enabled, accounts.id from accounts join users on users.account_id = accounts.id where users.id = ?", params["userID"].to_i, as: {Int32, Int32})

  # turns out the client never authenticates on this endpoint.
  # not sure why? this is kind of a Big Deal :( but oh well
  # keeping this code commented out incase this changes

  #user_id, account_id = Accounts.auth(params)

  #if account_id != target_account_id
  #  case comment_status
  #  when 0
  #    return "-1"
  #  when 1
  #    if !(user_id && account_id)
  #      return "-1"
  #    end
  #    if !Accounts.are_friends(account_id, target_account_id)
  #      return "-1"
  #    end
  #  when 2
  #    if account_id && Accounts.is_blocked_by(account_id, target_account_id)
  #      return "-1"
  #    end
  #  end
  #end

  comment_offset = (params["page"]? || "0").to_i * comments_per_page

  amount = DATABASE.scalar("select count(*) from comments where user_id = ?", params["userID"].to_i).as(Int64)

  comments_str = [] of String

  DATABASE.query("select comments.id, comment, comments.created_at, likes, level_id, users.username, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special from comments join users on users.id = user_id where user_id = ? order by comments.created_at desc limit #{comments_per_page} offset #{comment_offset}", params["userID"]) do |rs|
    rs.each do
      id = rs.read(Int32)
      comment = rs.read(String)
      created_at = rs.read(String)
      likes = rs.read(Int32)
      level_id = rs.read(Int32)
      username = rs.read(String)
      icon_type = rs.read(Int32)
      color1 = rs.read(Int32)
      color2 = rs.read(Int32)

      icon_value = [rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32)][icon_type]

      special = rs.read(Int32)

      comments_str << [
        Format.fmt_comment({
          1 => level_id,
          2 => Base64.urlsafe_encode(comment),
          3 => target_account_id,
          4 => likes,
          5 => 0, # dislikes; unused
          6 => id,
          7 => likes <= (config_get("comments.spam_thres").as?(Int64) || -3),
          9 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
        }),
        Format.fmt_comment({
          1 => username || "-",
          9 => icon_value,
          10 => color1,
          11 => color2,
          14 => icon_type,
          15 => special,
          16 => target_account_id
        })
      ].join(":")
    end
  end

  search_meta = "#{amount}:#{comment_offset}:#{comments_per_page}"

  [comments_str.join("|"), search_meta].join("#")
}
