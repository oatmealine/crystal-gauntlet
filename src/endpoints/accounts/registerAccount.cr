require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/registerGJAccount.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  if config_get("accounts.allow_registration").as(Bool | Nil) == false
    return "-1"
  end

  username = Clean.clean_basic(params["userName"])
  password = params["password"]
  email = params["email"]

  # caps checks aren't required because `username` is already COLLATE NOCASE in the db
  username_exists = DATABASE.scalar "select count(*) from accounts where username = ?", username
  if username_exists != 0
    return "-2"
  end

  # todo: email checks, conditionally?

  password_hash = Crypto::Bcrypt::Password.create(password, cost: 10).to_s
  gjp2 = CrystalGauntlet::GJP.hash(password)
  next_id = (DATABASE.scalar("select max(id) from accounts").as(Int64 | Nil) || 0) + 1
  DATABASE.exec "insert into accounts (id, username, password, email, gjp2) values (?, ?, ?, ?, ?)", next_id, username, password_hash, email, gjp2

  user_id = (DATABASE.scalar("select max(id) from users").as(Int64 | Nil) || 0) + 1
  DATABASE.exec "insert into users (id, account_id, username, registered) values (?, ?, ?, 1)", user_id, next_id, username
  "1"
}
