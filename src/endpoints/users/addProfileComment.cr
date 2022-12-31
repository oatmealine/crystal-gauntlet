require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJAccComment20.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  comment = params["comment"]?

  if comment && comment != ""
    # todo: cap comment size
    comment_value = Base64.decode_string comment # usual b64, surprisingly
    next_id = (DATABASE.scalar("select max(id) from account_comments").as(Int64 | Nil) || 0) + 1
    DATABASE.exec("insert into account_comments (id, account_id, comment) values (?, ?, ?)", next_id, account_id, comment_value)
    return "1"
  else
    return "-1"
  end
}
