require "uri"
require "http-session"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/login"] = ->(context : HTTP::Server::Context) {
  if session = CrystalGauntlet.sessions.get(context)
    logged_in = true
    account_id = session.account_id
    user_id = session.user_id
    username = session.username
  else
    logged_in = false
    account_id = nil
    user_id = nil
    username = nil
  end

  body = context.request.body
  if body
    begin
      params = URI::Params.parse(body.gets_to_end)
      username = params["username"].strip
      password = params["password"].strip

      if username.empty? || password.empty?
        raise "Invalid username or password"
      end

      # todo: dedup this code with the login account endpoint maybe
      result = DATABASE.query_all("select id, password from accounts where username = ?", username, as: {Int32, String})
      if result.size > 0
        account_id, hash = result[0]
        bcrypt = Crypto::Bcrypt::Password.new(hash)

        if bcrypt.verify(password)
          user_id = Accounts.get_user_id(account_id)
          logged_in = true
          LOG.debug { "#{username} logged in" }
          CrystalGauntlet.sessions.set(context, UserSession.new(username, account_id, user_id))
        else
          raise "Invalid password"
        end
      else
        raise "No such user exists"
      end
    rescue error
      LOG.error(exception: error) {"whar...."}
    end
  end

  if logged_in
    context.response.headers.add("Location", "#{context.request.query_params["redir"]? || "/accounts"}")
    context.response.status = HTTP::Status::SEE_OTHER
    return
  else
    ECR.embed("./public/template/login.ecr", context.response)
  end
}
