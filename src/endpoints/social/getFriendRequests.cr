require "uri"

include CrystalGauntlet

requests_per_page = 10

CrystalGauntlet.endpoints["/getGJFriendRequests20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  get_sent = params["getSent"]? == "1"

  page_offset = (params["page"]? || "0").to_i * requests_per_page

  requests_count = DATABASE.scalar("select count(*) from friend_requests where #{get_sent ? "from_account_id" : "to_account_id"} = ?", account_id)

  requests = [] of String

  DATABASE.query_each("select friend_requests.id, users.account_id, body, friend_requests.created_at, read_at, users.id, users.username, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special from friend_requests join users on users.id = #{get_sent ? "to_account_id" : "from_account_id"} where #{get_sent ? "from_account_id" : "to_account_id"} = ? limit #{requests_per_page} offset #{page_offset}", account_id) do |rs|
    id = rs.read(Int32)
    from_account_id = rs.read(Int32)
    body = rs.read(String)
    created_at = rs.read(String)
    read_at = rs.read(String?)

    from_user_id = rs.read(Int32)
    username = rs.read(String)

    icon_type = rs.read(Int32)
    color1 = rs.read(Int32)
    color2 = rs.read(Int32)

    icon_value = [rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32), rs.read(Int32)][icon_type]

    special = rs.read(Int32)

    requests << Format.fmt_hash({
      1 => username,
      2 => from_user_id,
      9 => icon_value,
      10 => color1,
      11 => color2,
      14 => icon_type,
      15 => special,
      16 => from_account_id,
      32 => id,
      35 => Base64.urlsafe_encode(body),
      37 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
      41 => read_at.is_a?(Nil)
    })
  end

  searchMeta = "#{requests_count}:#{page_offset}:#{requests_per_page}"

  return requests.join("|") + "#" + searchMeta
}
