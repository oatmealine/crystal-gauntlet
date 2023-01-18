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

  notifications = DATABASE.query_all("select type, target, details, read_at, created_at from notifications where account_id = ? order by created_at desc", account_id, as: {String, Int32?, String, String?, String})
    .map {|type, target, details, read_at, created_at| {
      type: type,
      target: target,
      details: Notifications::NotificationDetails.from_json(details),
      read_at: read_at,
      created_at: created_at
    } }

  # mark all as read
  DATABASE.exec("update notifications set read_at = ? where read_at is null and account_id = ?", Time.utc.to_s(Format::TIME_FORMAT), account_id)
  unread_notifications = false

  ECR.embed("./public/template/notifications.ecr", context.response)
}
