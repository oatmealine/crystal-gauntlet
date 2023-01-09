require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/requestUserAccess.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end
  
  rank = Ranks.get_rank(account_id)
  rank.is_mod ? "1" : "-1"
}
