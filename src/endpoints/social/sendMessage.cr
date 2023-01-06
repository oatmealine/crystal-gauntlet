require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/uploadGJMessage20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  # todo: check for blocks
  if DATABASE.scalar("select count(*) from accounts where id = ?", params["toAccountID"].to_i).as(Int64) == 0
    return "-1"
  end

  message_status = DATABASE.scalar("select messages_enabled from accounts where id = ?", account_id).as(Int64)
  case message_status
  when 0
    return "-1"
  when 1
    if !Accounts.are_friends(account_id, params["toAccountID"].to_i)
      return "-1"
    end
  when 2
    # go ahead
  end

  next_message_id = IDs.get_next_id("messages")
  DATABASE.exec("insert into messages (id, from_account_id, to_account_id, subject, body) values (?, ?, ?, ?, ?)", next_message_id, account_id, params["toAccountID"].to_i, Base64.decode_string(params["subject"])[..35-1], String.new(XorCrypt.encrypt_string(Base64.decode_string(params["body"])[..200-1], XorCrypt::MESSAGE_XOR_KEY)))

  return "1"
}
