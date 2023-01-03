require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJAccComment20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  comment = params["comment"]?

  if comment && comment != ""
    # todo: cap comment size
    comment_value = Base64.decode_string comment # usual b64, surprisingly
    next_id = IDs.get_next_id("account_comments")
    DATABASE.exec("insert into account_comments (id, account_id, comment) values (?, ?, ?)", next_id, account_id, comment_value)
    return "1"
  else
    return "-1"
  end
}
