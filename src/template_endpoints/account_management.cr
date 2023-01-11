include CrystalGauntlet

CrystalGauntlet.template_endpoints["/#{config_get("general.append_path").as(String | Nil) || ""}accounts/accountManagement.php"] = ->(context : HTTP::Server::Context) {
  context.response.headers.add("Location", "/accounts/")
  context.response.status = HTTP::Status::MOVED_PERMANENTLY
}

CrystalGauntlet.template_endpoints["/accounts"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"

  user_id = nil
  username = nil
  Templates.auth()

  stars, demons, coins, user_coins, diamonds, creator_points = DATABASE.query_one("select stars, demons, coins, user_coins, diamonds, creator_points from users where id = ?", user_id, as: {Int32, Int32, Int32, Int32, Int32, Int32})

  ECR.embed("./public/template/account_management.ecr", context.response)
}
