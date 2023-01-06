require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/deleteGJFriendRequests20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  own_request = params["isSender"]? == "1"

  if DATABASE.scalar("select count(*) from friend_requests where #{own_request ? "to_account_id" : "from_account_id"} = ?", params["targetAccountID"].to_i).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("delete from friend_requests where #{own_request ? "to_account_id" : "from_account_id"} = ?", params["targetAccountID"].to_i)

  return "1"
}
