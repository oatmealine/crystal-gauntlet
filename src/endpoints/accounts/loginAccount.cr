require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/loginGJAccount.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  username = params["userName"]
  password = params["password"]
  result = DATABASE.query_all("select id, password from accounts where username = ?", username, as: {Int32, String})
  if result.size > 0
    account_id, hash = result[0]
    bcrypt = Crypto::Bcrypt::Password.new(hash)

    if bcrypt.verify(password)
      user_id = Accounts.get_user_id(account_id)
      "#{account_id},#{user_id}"
    else
      return "-12"
    end
  else
    return "-1"
  end
}
