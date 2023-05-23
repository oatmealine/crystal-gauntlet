require "ecr"

include CrystalGauntlet

levels_per_page = 10

CrystalGauntlet.template_endpoints[{
  name: "list_levels",
  path: "/tools/levels",
  methods: ["get"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.content_type = "text/html"
  page = (context.request.query_params["page"]? || "0").to_i? || 0
  total_levels = DATABASE.scalar("select count(*) from levels").as(Int64)
  levels = DATABASE.query_all("select levels.id, name, users.username, levels.community_difficulty, levels.difficulty, levels.demon_difficulty, levels.featured, levels.epic from levels left join users on levels.user_id = users.id order by levels.id desc limit #{levels_per_page} offset #{page * levels_per_page}", as: {Int32, String, String, Int32?, Int32?, Int32?, Bool, Bool})
  ECR.embed("./public/template/levels.ecr", context.response)
}
