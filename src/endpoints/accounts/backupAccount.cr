require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/backupGJAccount.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  user_id, account_id = Accounts.auth(params)
  if !(user_id && account_id)
    return "-1"
  end

  data = params["saveData"].split(';')

  

  "1"
}
