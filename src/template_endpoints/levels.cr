require "ecr"

include CrystalGauntlet

levels_per_page = 10

CrystalGauntlet.template_endpoints[{
  name: "list_levels",
  path: "/levels",
  methods: ["get"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.content_type = "text/html"
  page = (context.request.query_params["page"]? || "0").to_i? || 0
  total_levels = DATABASE.scalar("select count(*) from levels").as(Int64)
  levels = DATABASE.query_all("select levels.id, name, users.username, levels.community_difficulty, levels.difficulty, levels.demon_difficulty, levels.featured, levels.epic from levels left join users on levels.user_id = users.id order by levels.id desc limit #{levels_per_page} offset #{page * levels_per_page}", as: {Int32, String, String, Int32?, Int32?, Int32?, Bool, Bool})
  ECR.embed("./public/template/levels.ecr", context.response)
}

CrystalGauntlet.template_endpoints[{
  name: "level_page",
  path: "/levels/{id<\\d+>}",
  methods: ["get"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.content_type = "text/html"
  id = params["id"].as(String).to_i

  begin
    name, username, difficulty_community, difficulty_set, demon_difficulty_int, featured, epic, rated_coins, downloads, likes, stars, description, song_id, song_name, song_author, song_url, song_author_url = DATABASE.query_one("select levels.name, users.username, community_difficulty, difficulty, demon_difficulty, featured, epic, rated_coins, downloads, likes, levels.stars, description, song_id, song_data.name, song_authors.name, songs.url, song_authors.source from levels left join users on levels.user_id = users.id left join songs on songs.id = levels.song_id left join song_data on song_data.id = levels.song_id left join song_authors on song_data.author_id = song_authors.id where levels.id = ?", id, as: {String, String, Int32?, Int32?, Int32?, Bool, Bool, Bool, Int32, Int32, Int32?, String, Int32, String?, String?, String?, String?})
  rescue err
    LOG.error {"whar.... #{err}"}
    context.response.status = HTTP::Status::NOT_FOUND
    return
  end

  scores = DATABASE.query_all("select distinct percent, level_scores.coins, users.username, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special, set_at from level_scores join users on level_scores.account_id = users.account_id where level_id = ? order by percent desc, level_scores.coins desc, set_at limit 25", id, as: {Int32, Int32, String, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, String})

  comments = DATABASE.query_all("select comment, comments.created_at, users.username, users.icon_type, users.color1, users.color2, users.cube, users.ship, users.ball, users.ufo, users.wave, users.robot, users.spider, users.special from comments left join users on comments.user_id = users.id where level_id = ? order by comments.created_at asc limit 20", id, as: {String, String, String, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32})

  ECR.embed("./public/template/level.ecr", context.response)
}
