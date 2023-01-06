require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJUserInfo20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)

  id, username, is_admin, messages_enabled, friend_requests_enabled, comments_enabled, youtube_url, twitter_url, twitch_url, created_at, user_id, stars, demons, coins, user_coins, diamonds, orbs, creator_points, icon_type, color1, color2, glow, cube, ship, ball, ufo, wave, robot, spider, explosion = DATABASE.query_one("select accounts.id, accounts.username, is_admin, messages_enabled, friend_requests_enabled, comments_enabled, youtube_url, twitter_url, twitch_url, accounts.created_at, users.id, stars, demons, coins, user_coins, diamonds, orbs, creator_points, icon_type, color1, color2, glow, cube, ship, ball, ufo, wave, robot, spider, explosion from accounts join users on accounts.id = users.account_id where accounts.id = ?", params["targetAccountID"], as: {Int32, String, Int32, Int32, Int32, Int32, String?, String?, String?, String, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32})

  is_friend = DATABASE.scalar("select count(*) from friend_links where (account_id_1 = ? and account_id_2 = ?) or (account_id_2 = ? and account_id_1 = ?)", account_id, id, account_id, id).as(Int64) > 0
  begin
    friend_request_id, friend_request_body, friend_request_created_at, from = DATABASE.query_one("select id, body, created_at, from_account_id from friend_requests where from_account_id = ? or to_account_id = ?", id, id, as: {Int32, String, String, Int32})
  rescue
  end

  return CrystalGauntlet::Format.fmt_hash({
    1 => username,
    2 => user_id,
    3 => stars,
    4 => demons,
    8 => creator_points,
    10 => color1,
    11 => color2,
    13 => coins,
    16 => id,
    17 => user_coins,
    # todo: messages can actually be disabled for _everyone_; this is actually an enum (0: all, 1: only friends, 2: none)
    18 => !messages_enabled,
    19 => !friend_requests_enabled,
    20 => youtube_url || "",
    21 => cube,
    22 => ship,
    23 => ball,
    24 => ufo,
    25 => wave,
    26 => robot,
    28 => glow,
    # registered or not; always 1 here
    29 => 1,
    30 => 1, # rank; todo
    # isnt (0) or is (1) friend or (3) incoming request or (4) outgoing request
    31 => friend_request_id ? (from == account_id ? 4 : 3) : (is_friend ? 1 : 0),
    32 => friend_request_id,
    35 => friend_request_body,
    37 => friend_request_created_at ? Time.parse(friend_request_created_at, Format::TIME_FORMAT, Time::Location::UTC) : "",
    38 => account_id == id ? DATABASE.scalar("select count(*) from messages where (to_account_id = ? and read_at is null)", id).as(Int64) : 0,
    39 => account_id == id ? DATABASE.scalar("select count(*) from friend_requests where (to_account_id = ? and read_at is null)", id).as(Int64) : 0,
    40 => account_id == id ? DATABASE.scalar("select count(*) from friend_links where (account_id_1 = ? and read_at_1 is null) or (account_id_2 = ? and read_at_2 is null)", id, id).as(Int64) : 0,
    43 => spider,
    44 => twitter_url || "",
    45 => twitch_url || "",
    46 => diamonds,
    48 => explosion,
    # badge, todo
    49 => 0,
    # todo: this is actually also an enum (0: all, 1: only friends, 2: none)
    50 => !comments_enabled,
  })
}
