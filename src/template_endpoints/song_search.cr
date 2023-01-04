require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/tools/song_search"] = ->(context : HTTP::Server::Context): String {
  error = nil
  songs = nil
  result_limit = 10
  body = context.request.body
  if body
    begin
      params = URI::Params.parse(body.gets_to_end)
      query = "%#{params["query"]}%"
      songs = DATABASE.query_all("select song_data.id, song_authors.name, song_data.name from song_data join song_authors on song_authors.id = song_data.author_id where song_data.id = ? or song_authors.name like ? or song_data.name like ? limit #{result_limit}", params["query"], query, query, as: {Int32, String, String})
    rescue error
      ECR.render("./public/template/song_search.ecr")
    else
      ECR.render("./public/template/song_search.ecr")
    end
  end

  ECR.render("./public/template/song_search.ecr")
}
