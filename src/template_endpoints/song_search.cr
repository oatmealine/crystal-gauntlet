require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[{
  name: "song_search",
  path: "/tools/song_search",
  methods: ["get", "post"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.content_type = "text/html"

  error = nil
  songs = nil
  body = context.request.body
  if body
    begin
      params = URI::Params.parse(body.gets_to_end)
      query = "%#{params["query"]}%"
      songs = DATABASE.query_all("select song_data.id, song_authors.name, song_data.name from song_data join song_authors on song_authors.id = song_data.author_id where song_data.id = ? or song_authors.name like ? or song_data.name like ?", params["query"], query, query, as: {Int32, String, String})
    rescue error
      ECR.embed("./public/template/song_search.ecr", context.response)
    else
      ECR.embed("./public/template/song_search.ecr", context.response)
    end
  else
    ECR.embed("./public/template/song_search.ecr", context.response)
  end
}
