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

  stars, demons, coins, user_coins, diamonds, creator_points, icon_type, color1, color2, cube, ship, ball, ufo, wave, robot, spider, glow = DATABASE.query_one("select stars, demons, coins, user_coins, diamonds, creator_points, icon_type, color1, color2, cube, ship, ball, ufo, wave, robot, spider, glow from users where id = ?", user_id, as: {Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32})

  icon_value = [cube, ship, ball, ufo, wave, robot, spider][icon_type]
  type_str = ["cube", "ship", "ball", "ufo", "wave", "robot", "spider"][icon_type]

  ECR.embed("./public/template/account_management.ecr", context.response)
}
