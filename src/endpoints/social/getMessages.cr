require "uri"

include CrystalGauntlet

messages_per_page = 10

CrystalGauntlet.endpoints["/getGJMessages20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  get_sent = params["getSent"]? == "1"

  page_offset = (params["page"]? || "0").to_i * messages_per_page

  message_count = DATABASE.scalar("select count(*) from messages where #{get_sent ? "from_account_id" : "to_account_id"} = ?", account_id)

  messages = [] of String

  DATABASE.query_each("select messages.id, users.account_id, subject, body, messages.created_at, read_at, users.id, users.username from messages join users on users.account_id = #{get_sent ? "to_account_id" : "from_account_id"} where #{get_sent ? "from_account_id" : "to_account_id"} = ? order by messages.created_at desc limit #{messages_per_page} offset #{page_offset}", account_id) do |rs|
    id = rs.read(Int32)
    from_account_id = rs.read(Int32)
    subject = rs.read(String)
    body = rs.read(String)
    created_at = rs.read(String)
    read_at = rs.read(String?)

    from_user_id = rs.read(Int32)
    username = rs.read(String)

    messages << Format.fmt_hash({
      1 => id,
      2 => from_account_id,
      3 => from_user_id,
      4 => Base64.urlsafe_encode(subject),
      5 => Base64.urlsafe_encode(XorCrypt.encrypt_string(body, XorCrypt::MESSAGE_XOR_KEY)),
      6 => username,
      7 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
      8 => !read_at.is_a?(Nil),
      9 => get_sent
    })
  end

  if !get_sent
    DATABASE.exec("update messages set read_at = ? where read_at is null and to_account_id = ?", Time.utc.to_s(Format::TIME_FORMAT), account_id)
  end

  searchMeta = "#{message_count}:#{page_offset}:#{messages_per_page}"

  return messages.join("|") + "#" + searchMeta
}
