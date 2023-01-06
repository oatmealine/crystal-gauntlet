require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJUserList20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  users = [] of String

  accounts = params["type"]? == "1" ?
    DATABASE.query_all("select from_account_id, to_account_id, '', '' from block_links where from_account_id = ? order by created_at desc", account_id, as: {Int32, Int32, String?, String?}) :
    DATABASE.query_all("select account_id_1, account_id_2, read_at_1, read_at_2 from friend_links where account_id_1 = ? or account_id_2 = ? order by created_at desc", account_id, account_id, as: {Int32, Int32, String?, String?})

  accounts.each() do |account_id_1, account_id_2, read_at_1, read_at_2|
    read_at = account_id_1 == account_id ? read_at_1 : read_at_2
    other_account_id = account_id_1 == account_id ? account_id_2 : account_id_1

    # this would be Cool to do as a join. However , linking both the first and second account id and
    # juggling the two would be absolute hell
    username, user_id, cube, ship, ball, ufo, wave, robot, spider, icon_type, color1, color2, special, messages_enabled = DATABASE.query_one("select users.username, users.id, cube, ship, ball, ufo, wave, robot, spider, icon_type, color1, color2, special, messages_enabled from accounts join users on users.account_id = accounts.id where accounts.id = ?", other_account_id, as: {String, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32})

    icon_value = [cube, ship, ball, ufo, wave, robot, spider][icon_type]

    users << Format.fmt_hash({
      1 => username,
      2 => user_id,
      9 => icon_value,
      10 => color1,
      11 => color2,
      14 => icon_type,
      15 => special,
      16 => other_account_id,
      18 => messages_enabled,
      41 => read_at.is_a?(Nil)
    })
  end

  if params["type"]? != "1"
    DATABASE.exec("update friend_links set read_at_1 = ? where account_id_1 = ? and read_at_1 is null", Time.utc.to_s(Format::TIME_FORMAT), account_id)
    DATABASE.exec("update friend_links set read_at_2 = ? where account_id_2 = ? and read_at_2 is null", Time.utc.to_s(Format::TIME_FORMAT), account_id)
  end

  if users.empty?
    return "-2"
  end

  return users.join("|")
}
