require "uri"

include CrystalGauntlet

private PAD_STR = "_____" # meaningless but necessary

private def get_chk_value(chk_str : String)
  XorCrypt.encrypt_string(Base64.decode_string(chk_str[5..]), XorCrypt::CHEST_XOR_KEY)
end

private def get_rand(type : String, large = false)
  base = "chests.#{large ? "large" : "small"}.#{type}"
  min = config_get("#{base}_min").as?(Int64) || 0
  max = config_get("#{base}_max").as?(Int64) || 0
  increment = config_get("#{base}_increment").as?(Int64) || 1

  ((Random.rand(min.to_f .. (max.to_f + 1)) / increment).floor() * increment).to_i
end

private REWARD_TYPES = StaticArray["orbs", "diamonds", "shards", "keys"]

private def get_chest(account_id : Int32, large = false) : {Int32?, Int32?}
  begin
    total, next_at = DATABASE.query_one("select total_opened, next_at from #{large ? "large_chests" : "small_chests"} where account_id = ?", account_id, as: {Int32, String})
  rescue
    {0, 0}
  else
    {total, Math.max((Time.parse(next_at, Format::TIME_FORMAT, Time::Location::UTC) - Time.utc).total_seconds.to_i, 0)}
  end
end

private def claim_chest(account_id : Int32, prev_count : Int32, large = false)
  table = large ? "large_chests" : "small_chests"
  timer = config_get("chests.#{large ? "large" : "small"}.timer").as?(Int64) || 0
  next_at = (Time.utc + timer.seconds).to_s(Format::TIME_FORMAT)
  if DATABASE.scalar("select count(*) from #{table} where account_id = ?", account_id).as(Int64) > 0
    DATABASE.exec("update #{table} set total_opened = ?, next_at = ? where account_id = ?", prev_count + 1, next_at, account_id)
  else
    DATABASE.exec("insert into #{table} (account_id, total_opened, next_at) values (?, ?, ?)", account_id, prev_count + 1, next_at)
  end

  return timer
end

CrystalGauntlet.endpoints["/getGJRewards.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  if !config_get("chests.enabled").as?(Bool)
    LOG.debug { "chests disabled" }
    return "-1"
  end

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  small_total, small_next = get_chest(account_id, false)
  large_total, large_next = get_chest(account_id, true)

  LOG.debug { "small: #{small_next}s, large: #{large_next}s" }
  # todo: figure out why opening one chest resets the other visually

  case params["rewardType"]
  when "1"
    if small_next > 0
      LOG.debug { "you still need to wait #{small_next}s" }
      return "-1"
    end
    small_next = claim_chest(account_id, small_total, false)
  when "2"
    if large_next > 0
      LOG.debug { "you still need to wait #{large_next}s" }
      return "-1"
    end
    large_next = claim_chest(account_id, large_total, true)
  end

  resp = [
    PAD_STR,
    user_id,
    String.new(get_chk_value(params["chk"])),
    params["udid"],
    account_id,

    # small
    small_next, REWARD_TYPES.map {|t| get_rand(t, false)}.join(","), small_total,
    # large
    large_next, REWARD_TYPES.map {|t| get_rand(t, true)}.join(","),  large_total,

    params["rewardType"].to_i? || 0
  ].join(":")

  resp_str = Base64.urlsafe_encode(XorCrypt.encrypt_string(resp, XorCrypt::CHEST_XOR_KEY))

  return PAD_STR + resp_str + "|" + Hashes.gen_solo_4(resp_str)
}
