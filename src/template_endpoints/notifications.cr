include CrystalGauntlet

CrystalGauntlet.template_endpoints["/accounts/notifications"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"

  account_id = nil
  user_id = nil
  username = nil
  Templates.auth()

  icon_type, color1, color2, cube, ship, ball, ufo, wave, robot, spider, glow = DATABASE.query_one("select icon_type, color1, color2, cube, ship, ball, ufo, wave, robot, spider, glow from users where id = ?", user_id, as: {Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32})

  icon_value = [cube, ship, ball, ufo, wave, robot, spider][icon_type]
  type_str = ["cube", "ship", "ball", "ufo", "wave", "robot", "spider"][icon_type]

  notification_count = DATABASE.scalar("select count(*) from notifications where account_id = ? and read_at is null", account_id).as(Int64)
  unread_notifications = notification_count > 0

  ECR.embed("./public/template/notifications.ecr", context.response)
}
