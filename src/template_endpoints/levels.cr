require "ecr"

include CrystalGauntlet

levels_per_page = 10

CrystalGauntlet.template_endpoints["/tools/levels"] = ->(context : HTTP::Server::Context): String {
  page = (context.request.query_params["page"]? || "0").to_i? || 0
  total_levels = DATABASE.scalar("select count(*) from levels").as(Int64)
  levels = DATABASE.query_all("select levels.id, name, users.username, levels.community_difficulty, levels.difficulty, levels.featured, levels.epic from levels left join users on levels.user_id = users.id limit #{levels_per_page} offset #{page * levels_per_page}", as: {Int32, String, String, Int32?, Int32?, Bool, Bool})
  ECR.render("./public/template/levels.ecr")
}
