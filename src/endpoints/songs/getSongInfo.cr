require "uri"
require "crystagiri"
require "http/client"
require "digest/sha256"

include CrystalGauntlet

NEWGROUNDS_AUDIO_URL_REGEX = /(?<!\\)"url":"(.+?)(?<!\\)"/

def unescape_string(s : String) : String
  s.gsub(/\\(.)/) { |v| v[1] }
end

CrystalGauntlet.endpoints["/getGJSongInfo.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  song_id = params["songID"].to_i32

  DATABASE.query("select name, author_id, author_name, size, download, disabled from songs where id = ?", song_id) do |rs|
    if rs.move_next
      song_name = rs.read(String)
      author_id = rs.read(Int32)
      author_name = rs.read(String)
      size = rs.read(Int32)
      download = rs.read(String)
      disabled = rs.read(Int32)

      if disabled == 1
        return "-2"
      end

      return Format.fmt_song({
        1 => song_id,
        2 => song_name,
        3 => author_id,
        4 => author_name,
        5 => size / (1000 * 1000),
        6 => "",
        10 => download,
        7 => "",
        8 => "0"
      })
    end
  end

  if Songs.is_reuploaded_song(song_id)
    # todo
    "-1"
  else
    # todo: maybe use yt-dlp? for other sources too
    doc = Crystagiri::HTML.from_url "https://www.newgrounds.com/audio/listen/#{song_id}"

    song_name = (doc.css("title") { |d| })[0].content
    song_artist = (doc.css(".item-details-main > h4 > a") { |d| d })[0].content
    song_url_str = (doc.css("script") { |d| })
      .map { |d| d.node.to_s.match(NEWGROUNDS_AUDIO_URL_REGEX) }
      .reduce { |acc, d| acc || d }
      .not_nil![1]

    # todo: proxy locally
    song_url = unescape_string(song_url_str).split("?")[0].sub("https://", "http://")

    # todo: consider hashes?
    size = 0

    HTTP::Client.head(song_url) do |response|
      size = response.headers["content-length"].to_i
    end

    author_id = 9 # todo: what is this needed for?

    DATABASE.exec("insert into songs (id, name, author_id, author_name, size, download) values (?, ?, ?, ?, ?, ?)", song_id, song_name, author_id, song_artist, size, song_url)

    return Format.fmt_song({
      1 => song_id,
      2 => song_name,
      3 => author_id,
      4 => song_artist,
      5 => size / (1000 * 1000),
      6 => "",
      10 => song_url,
      7 => "",
      8 => "0"
    })
  end
}
