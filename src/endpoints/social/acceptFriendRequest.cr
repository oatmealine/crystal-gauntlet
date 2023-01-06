require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/acceptGJFriendRequest20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  begin
    from_account_id = DATABASE.query_one("select from_account_id from friend_requests where id = ?", params["requestID"], as: {Int32})
  rescue
    # no such friend request
    return "-1"
  end

  DATABASE.exec("delete from friend_requests where (from_account_id = ? and to_account_id = ?) or (to_account_id = ? and from_account_id = ?)", account_id, from_account_id, account_id, from_account_id)
  DATABASE.exec("insert into friend_links (account_id_1, account_id_2) values (?, ?)", from_account_id, account_id)

  return "1"
}
