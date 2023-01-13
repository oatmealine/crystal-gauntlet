require "uri"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/accounts/settings"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"

  account_id = nil
  user_id = nil
  username = nil

  Templates.auth()

  email = DATABASE.query_one("select email from accounts where id = ?", account_id, as: {String})

  result = nil

  params = context.request.body.try { |b| URI::Params.parse(b.gets_to_end) }
  if params
    begin
      if params["username"]? && params["username"] != username
        # todo: dedup this and the gd register endpoint
        username = Clean.clean_basic(params["username"].strip)
        if username.size < 3
          raise "Username must at least be 3 characters long"
        end
        if username.size > 16
          raise "Username must at most be 16 characters long"
        end

        if DATABASE.scalar("select count(*) from accounts where username = ?", username).as(Int64) > 0
          raise "Username already taken"
        end

        DATABASE.exec("update accounts set username = ? where id = ?", username, account_id)
        DATABASE.exec("update users set username = ? where id = ?", username, user_id)

        # refresh session
        CrystalGauntlet.sessions.set(context, UserSession.new(username, account_id.not_nil!, user_id.not_nil!))

        result = "Changed username successfully"
      end

      if params["email"]?
        email = params["email"].strip

        if email.size > 254
          raise "Invalid email (too long)"
        end

        DATABASE.exec("update accounts set email = ? where id = ?", email, account_id)
      end

      if params["old_password"]? && params["new_password"]? && params["repeat_new_password"]?
        if params["repeat_new_password"] != params["new_password"]
          raise "New password and repeated password do not match"
        end

        new_password = params["new_password"].strip

        # todo: dedup this and gd register endpoint
        if new_password.size < 6
          raise "New password must be at least 6 characters long"
        end

        old_hash = DATABASE.query_one("select password from accounts where username = ?", username, as: {String})
        bcrypt = Crypto::Bcrypt::Password.new(old_hash)

        if !bcrypt.verify(params["old_password"])
          raise "Invalid old password"
        end

        password_hash = Crypto::Bcrypt::Password.create(new_password, cost: 10).to_s
        gjp2 = CrystalGauntlet::GJP.hash(new_password)
        DATABASE.exec("update accounts set password = ?, gjp2 = ? where id = ?", password_hash, gjp2, account_id)

        result = "Changed password successfully"
      end
    rescue error
      LOG.error {"whar.... #{error}"}
    end
  end

  ECR.embed("./public/template/account_settings.ecr", context.response)
}
