require "uri"
require "http/client"
require "digest/sha256"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJSongInfo.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  LOG.debug { params.inspect }

  song_id = params["songID"].to_i32

  song = Songs.fetch_song(song_id, true)

  if song != nil
    begin
      song_name, song_author_id, song_author_name, song_size, song_download = song.not_nil!
    rescue
      return "-1"
    else
      return Format.fmt_song({
        1 => song_id,
        2 => song_name,
        3 => song_author_id,
        4 => song_author_name,
        5 => (song_size || 0) / (1000 * 1000),
        6 => "", # yt video id; unused i think?
        7 => "", # yt video url; unused also??
        8 => "1", # if the song is verified/scouted
        10 => song_download || "",
      })
    end
  else
    return "-2"
  end
}
