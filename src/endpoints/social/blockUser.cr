require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/blockGJUser20.php"] = ->(context : HTTP::Server::Context): String {
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
  if DATABASE.scalar("select count(*) from block_links where from_account_id = ? and to_account_id = ?", account_id, target_account_id).as(Int64) > 0
    return "-1"
  end

  DATABASE.exec("insert into block_links (from_account_id, to_account_id) values (?, ?)", account_id, target_account_id)
  DATABASE.exec("delete from messages where from_account_id = ? and to_account_id = ?", target_account_id, account_id)
  DATABASE.exec("delete from friend_requests where from_account_id = ? and to_account_id = ?", target_account_id, account_id)
  DATABASE.exec("delete from friend_links where (account_id_1 = ? and account_id_2 = ?) or (account_id_2 = ? and account_id_1 = ?)", target_account_id, account_id, target_account_id, account_id)

  return "1"
}
