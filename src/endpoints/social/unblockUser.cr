require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/unblockGJUser20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  target_account_id = params["targetAccountID"].to_i

  if DATABASE.scalar("select count(*) from accounts where id = ?", target_account_id).as(Int64) == 0
    return "-1"
  end
  if DATABASE.scalar("select count(*) from block_links where from_account_id = ? and to_account_id = ?", account_id, target_account_id).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("delete from block_links where from_account_id = ? and to_account_id = ?", account_id, target_account_id)

  return "1"
}
