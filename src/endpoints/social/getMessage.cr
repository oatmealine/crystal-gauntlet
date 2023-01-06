require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/downloadGJMessage20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  message_id = params["messageID"].to_i

  id, from_account_id, to_account_id, subject, body, created_at, read_at, to_user_id, username = DATABASE.query_one("select messages.id, from_account_id, to_account_id, subject, body, messages.created_at, read_at, users.id, users.username from messages join users on users.account_id = to_account_id where messages.id = ?", message_id, as: {Int32, Int32, Int32, String, String, String, String?, Int32, String})

  if from_account_id != account_id && to_account_id != account_id
    return "-1"
  end

  DATABASE.exec("update messages set read_at = ? where read_at is null and id = ?", Time.utc.to_s(Format::TIME_FORMAT), message_id)

  return Format.fmt_hash({
    1 => id,
    2 => to_account_id,
    3 => to_user_id,
    4 => Base64.urlsafe_encode(subject),
    5 => Base64.urlsafe_encode(XorCrypt.encrypt_string(body, XorCrypt::MESSAGE_XOR_KEY)),
    6 => username,
    7 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
    8 => read_at.is_a?(Nil),
    9 => from_account_id == account_id
  })
}
