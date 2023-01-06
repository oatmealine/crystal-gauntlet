require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/deleteGJComment20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  comment_user_id, level_user_id = DATABASE.query_one("select comments.user_id, levels.user_id from comments join levels on levels.id = comments.id where comments.id = ?", params["commentID"].to_i, as: {Int32, Int32})

  if comment_user_id != user_id && level_user_id != user_id
    return "-1"
  end

  DATABASE.exec("delete from comments where id = ?", params["commentID"].to_i)

  return "1"
}
