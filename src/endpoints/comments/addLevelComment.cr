require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJComment21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    user_id, account_id = Accounts.auth_old(context.request, params)
    if !(user_id && account_id)
      return "-1"
    end
  end

  comment = params["comment"]?
  level_id = params["levelID"].to_i
  percent = (params["percent"]? || "nil").to_i?

  if percent && (percent < 0 || percent > 100)
    return "-1"
  end

  if comment && !comment.blank?
    comment_value = comment
    if params.has_key?("gameVersion")
      comment_value = Base64.decode_string(comment_value)[..100-1]
    else
      comment_value = comment_value[..100-1]
    end
    next_id = IDs.get_next_id("comments")
    DATABASE.exec("insert into comments (id, level_id, user_id, comment, percent) values (?, ?, ?, ?, ?)", next_id, level_id, user_id, comment_value, percent)
    return "1"
  else
    return "-1"
  end
}

CrystalGauntlet.endpoints["/uploadGJComment20.php"] = CrystalGauntlet.endpoints["/uploadGJComment21.php"]

CrystalGauntlet.endpoints["/uploadGJComment19.php"] = CrystalGauntlet.endpoints["/uploadGJComment21.php"]

