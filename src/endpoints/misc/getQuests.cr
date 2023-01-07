require "uri"

include CrystalGauntlet

private PAD_STR = "_____" # meaningless but necessary

private def get_chk_value(chk_str : String)
  XorCrypt.encrypt_string(Base64.decode_string(chk_str[5..]), XorCrypt::QUESTS_XOR_KEY)
end

private def get_quest_time(account_id : Int32)
  timer = config_get("quests.timer", 0_i64)

  begin
    next_str = DATABASE.query_one("select next_at from quest_timer where account_id = ?", account_id, as: {String})
  rescue
    next_at = (Time.utc + timer.seconds).to_s(Format::TIME_FORMAT)
    DATABASE.exec("insert into quest_timer (account_id, next_at) values (?, ?)", account_id, next_at)
    return 0
  else
    next_at = Time.parse(next_str, Format::TIME_FORMAT, Time::Location::UTC)
    seconds_left = (next_at - Time.utc).total_seconds.to_i
    if seconds_left <= 0
      next_at = (Time.utc + timer.seconds).to_s(Format::TIME_FORMAT)
      DATABASE.exec("update quest_timer set next_at = ? where account_id = ?", next_at, account_id)
    end

    return seconds_left
  end
end

private def type_to_i(type : String?)
  case type
  when "orb", "orbs"
    1
  when "coin", "coins"
    2
  when "star", "stars"
    3
  else
    1
  end
end

private def rand_quest(tier : Int32)
  pool = config_get("quests.tier_#{tier}").as?(Array)
  if !pool
    return ""
  end

  roll = rand(pool.size)
  quest = pool[roll]?.as?(Hash)

  if !quest
    return ""
  end

  [
    roll,
    type_to_i(quest["required_type"]?.as?(String)),
    quest["required_amt"]? || 0,
    quest["reward_diamonds"]? || 0,
    quest["name"]? || ""
  ].join(",")
end

CrystalGauntlet.endpoints["/getGJChallenges.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  if !config_get("quests.enabled").as?(Bool)
    LOG.debug { "quests disabled" }
    return "-1"
  end

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  time_left = get_quest_time(account_id)

  resp = [
    PAD_STR,
    user_id,
    String.new(get_chk_value(params["chk"])),
    params["udid"],
    account_id,
    time_left,

    rand_quest(1),
    rand_quest(2),
    rand_quest(3)
  ].join(":")

  resp_str = Base64.urlsafe_encode(XorCrypt.encrypt_string(resp, XorCrypt::QUESTS_XOR_KEY))

  return PAD_STR + resp_str + "|" + Hashes.gen_solo_3(resp_str)
}
