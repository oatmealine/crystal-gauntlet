require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJComment21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  comment = params["comment"]?
  level_id = params["levelID"].to_i
  percent = (params["percent"]? || "nil").to_i?

  if percent && (percent < 0 || percent > 100)
    return "-1"
  end

  if comment && comment != ""
    # todo: cap comment size
    comment_value = Base64.decode_string comment # usual b64, surprisingly
    next_id = IDs.get_next_id("comments")
    DATABASE.exec("insert into comments (id, level_id, user_id, comment, percent) values (?, ?, ?, ?, ?)", next_id, level_id, user_id, comment_value, percent)
    return "1"
  else
    return "-1"
  end
}
