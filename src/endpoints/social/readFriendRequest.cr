require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/readGJFriendRequest20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  if DATABASE.scalar("select count(*) from friend_requests where id = ? and to_account_id = ?", params["requestID"].to_i, account_id).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("update friend_requests set read_at = ? where id = ? and read_at is null", Time.utc.to_s(Format::TIME_FORMAT), params["requestID"].to_i)

  return "1"
}
