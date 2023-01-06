require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/backupGJAccount.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  #LOG.debug { params.inspect }

  username = params["userName"]
  password = params["password"]

  result = DATABASE.query_all("select id, password from accounts where username = ?", username, as: {Int32, String})
  if result.size > 0
    account_id, hash = result[0]
    bcrypt = Crypto::Bcrypt::Password.new(hash)

    if bcrypt.verify(password)
      folder = DATA_FOLDER / "saves"
      params.each do |key, _|
        if key.starts_with?("H4s")
          File.open(folder / "#{account_id}_levels.sav", "w") { |file| Base64.decode(key, file) }
        end
      end

      File.open(folder / "#{account_id}.sav", "w") { |file| Base64.decode(params["saveData"], file) }
      return "1"
    else
      return "-1"
    end
  else
    return "-1"
  end
}

CrystalGauntlet.endpoints["/database/accounts/backupGJAccountNew.php"] = CrystalGauntlet.endpoints["/accounts/backupGJAccount.php"]

