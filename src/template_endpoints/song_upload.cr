require "ecr"

include CrystalGauntlet

# this function exists because first id for songs is not 1
def get_next_song_id() : Int32
  begin
    id = DATABASE.query_one("select id from next_id where name = ?", "songs", as: {Int32})
  rescue
    next_id = config_get("songs.preserve_newgrounds_ids").as(Bool) ? Songs::REUPLOADED_SONG_ADD_ID : Songs::CUSTOM_SONG_START
    DATABASE.exec("insert into next_id (name, id) values (?, ?)", "songs", next_id)
    next_id
  else
    next_id = id + 1
    DATABASE.exec("update next_id set id = ? where name = ?", next_id, "songs")
    return next_id
  end
end

CrystalGauntlet.template_endpoints["/tools/song_upload"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"

  error = nil
  song_id = nil
  body = context.request.body
  if body
    begin
      params = URI::Params.parse(body.gets_to_end)
      song_id = get_next_song_id()
      DATABASE.exec("insert into songs (id, url) values (?, ?)", song_id, params["url"])
    rescue error
      # todo: HELP HOW DO I DO THIS BUT BETTER
      ECR.embed("./public/template/song_upload.ecr", context.response)
    else
      ECR.embed("./public/template/song_upload.ecr", context.response)
    end
  end

  ECR.embed("./public/template/song_upload.ecr", context.response)
}
