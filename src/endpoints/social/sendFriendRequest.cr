require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadFriendRequest20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  target_account_id = params["toAccountID"].to_i

  # todo: check for blocks
  if DATABASE.scalar("select count(*) from accounts where id = ?", target_account_id).as(Int64) == 0
    return "-1"
  end

  if DATABASE.scalar("select count(*) from friend_requests where (from_account_id = ? and to_account_id = ?) or (to_account_id = ? and from_account_id = ?)", account_id, target_account_id, account_id, target_account_id).as(Int64) > 0
    # already fr'd
    return "-1"
  end

  if DATABASE.scalar("select friend_requests_enabled from accounts where id = ?", target_account_id).as(Int64) == 0
    # disabled
    return "-1"
  end

  next_fr_id = IDs.get_next_id("friend_requests")
  DATABASE.exec("insert into friend_requests (id, from_account_id, to_account_id, body) values (?, ?, ?, ?)", next_fr_id, account_id, params["toAccountID"].to_i, Base64.decode_string(params["comment"])[..140-1])

  return "1"
}
