require "uri"
require "base64"
require "crypto/bcrypt/password"

include CrystalGauntlet

CrystalGauntlet.endpoints["/accounts/registerGJAccount.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  username = params["userName"]
  password = params["password"]
  email = params["email"]

  username_exists = DATABASE.scalar "select count(*) from accounts where username = ?", username
  if username_exists != 0
    return "-2"
  end

  password_hash = Crypto::Bcrypt::Password.create(password, cost: 10).to_s
  gjp2 = CrystalGauntlet::GJP.hash(password)
  next_id = (DATABASE.scalar("select max(id) from accounts").as(Int64 | Nil) || 0) + 1
  DATABASE.exec "insert into accounts (id, username, password, email, gjp2) values (?, ?, ?, ?, ?)", next_id, username, password_hash, email, gjp2

  user_id = (DATABASE.scalar("select max(id) from users").as(Int64 | Nil) || 0) + 1
  DATABASE.exec "insert into users (id, account_id, username, registered) values (?, ?, ?, 1)", user_id, next_id, username
  "1"
}
