require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/removeGJFriend20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  DATABASE.exec("delete from friend_links where (account_id_1 = ? and account_id_2 = ?) or (account_id_2 = ? and account_id_1 = ?)", account_id, params["targetAccountID"].to_i, account_id, params["targetAccountID"].to_i)

  return "1"
}
