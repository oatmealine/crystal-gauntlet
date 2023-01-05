require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/registerGJAccount.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  if config_get("accounts.allow_registration").as(Bool | Nil) == false
    return "-1"
  end

  username = Clean.clean_basic(params["userName"])
  password = params["password"]
  email = params["email"]

  if username != params["userName"]
    return "-4"
  end

  if password.size < 6
    return "-8"
  end
  if username.size < 3
    return "-9"
  end
  if username.size > 16
    return "-4"
  end
  if email.size > 254
    return "-6"
  end

  # caps checks aren't required because `username` is already COLLATE NOCASE in the db
  username_exists = DATABASE.scalar "select count(*) from accounts where username = ?", username
  if username_exists != 0
    return "-2"
  end

  # todo: email checks, conditionally?

  password_hash = Crypto::Bcrypt::Password.create(password, cost: 10).to_s
  gjp2 = CrystalGauntlet::GJP.hash(password)
  next_id = IDs.get_next_id("accounts")
  DATABASE.exec "insert into accounts (id, username, password, email, gjp2) values (?, ?, ?, ?, ?)", next_id, username, password_hash, email, gjp2

  user_id = IDs.get_next_id("users")
  DATABASE.exec "insert into users (id, account_id, username, registered) values (?, ?, ?, 1)", user_id, next_id, username
  "1"
}
