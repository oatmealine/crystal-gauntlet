require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/deleteGJMessages20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  message_id = params["messageID"].to_i

  id, from_account_id, to_account_id, subject, body, created_at, read_at, to_user_id, username = DATABASE.query_one("select messages.id, from_account_id, to_account_id, subject, body, messages.created_at, read_at, users.id, users.username from messages join users on users.id = to_account_id where messages.id = ?", message_id, as: {Int32, Int32, Int32, String, String, String, String?, Int32, String})

  if from_account_id != account_id && to_account_id != account_id
    return "-1"
  end

  DATABASE.exec("delete from messages where id = ?", message_id)

  return "1"
}
