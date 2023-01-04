require "ecr"
require "xml"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/tools/reupload"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"

  error = nil
  level_id = nil
  body = context.request.body
  if body
    begin
      params = URI::Params.parse(body.gets_to_end)
      remote_level_id = params["level_id"]

      resp = HTTP::Client.get "https://history.geometrydash.eu/api/v1/level/#{remote_level_id}/"
      if resp.status_code != 200
        raise "Recieved #{resp.status_code}"
      end
      data = JSON.parse(resp.body)

      level = data["records"].as_a
        .select { |rec| rec["level_string_available"] == true }
        .sort { |a, b| a["real_date"].as_s <=> b["real_date"].as_s }
        .last

      gmd_file = HTTP::Client.get "https://history.geometrydash.eu/level/#{remote_level_id}/#{level["id"]}/download/"
      level_data = Level.gmd_parse(gmd_file.body)

      # todo: deduplicate this and level uploads
      next_id = IDs.get_next_id("levels")

      # todo: reupload as reupload acc
      DATABASE.exec("insert into levels (id, name, user_id, description, original, game_version, binary_version, password, requested_stars, unlisted, version, extra_data, level_info, editor_time, editor_time_copies, song_id, length, objects, coins, has_ldm, two_player) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, Clean.clean_special(level_data["k2"]), 1, Base64.decode_string(Base64.decode_string(level_data["k3"])), nil, level_data["k17"].to_i32, (level_data["k50"]? || "0").to_i32, level_data["k41"]? ? level_data["k41"].to_i32 : nil, level_data["k66"].to_i32, 0, level_data["k16"].to_i32, Clean.clean_special(level["extra_string"].as_s? || Level::DEFAULT_EXTRA_STRING), Level::DEFAULT_LEVEL_INFO, (level_data["k80"]? || "0").to_i32, (level_data["k81"]? || "0").to_i32, (level_data["k8"]? || "0") == "0" ? level_data["k45"] : level_data["k8"], level["length"].as_i, level_data["k48"], (level_data["k64"]? || "0").to_i, (level_data["k72"]? || "0").to_i, (level_data["k43"]? || "0").to_i)

      File.write("data/#{next_id.to_s}.lvl", Base64.decode(level_data["k4"]))

      level_id = next_id
    rescue error
    end
  end

  ECR.embed("./public/template/reupload.ecr", context.response)
}
