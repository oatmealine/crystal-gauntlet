require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/syncGJAccount.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  username = params["userName"]
  password = params["password"]

  result = DATABASE.query_all("select id, password from accounts where username = ?", username, as: {Int32, String})
  if result.size > 0
    account_id, hash = result[0]
    bcrypt = Crypto::Bcrypt::Password.new(hash)
    
    if bcrypt.verify(password)
      folder = DATA_FOLDER / "saves"
      return "#{File.read(folder / "#{account_id}.sav")};#{File.read(folder / "#{account_id}_levels.sav")};21;30;a;a"
    else
      return "-1"
    end
  else
    return "-1"
  end
}

CrystalGauntlet.endpoints["/database/accounts/syncGJAccountNew.php"] = CrystalGauntlet.endpoints["/accounts/syncGJAccount.php"]

