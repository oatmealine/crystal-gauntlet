require "json"
require "db"

include CrystalGauntlet

module CrystalGauntlet::Songs
  extend self

  GD_AUDIO_FORMAT = "mp3"

  # todo: make this configurable
  REUPLOADED_SONG_ADD_ID = 5000000

  CUSTOM_SONG_START = 50

  # set in 6_songs.sql
  UNKNOWN_SONG_AUTHOR = 1

  def is_custom_song(id)
    id >= CUSTOM_SONG_START
  end

  def is_reuploaded_song(id)
    id >= REUPLOADED_SONG_ADD_ID
  end

  class SongMetadata
    def initialize(name : String, author : String, normalized_url : String, source : String, author_url : String, duration : Int32 | Nil, size : Int32 | Nil)
      @name = name
      @author = author
      @normalized_url = normalized_url
      @source = source
      @author_url = author_url
      @duration = duration
      @size = size
    end

    def name
      @name
    end
    def author
      @author
    end
    def normalized_url
      @normalized_url
    end
    def source
      @source
    end
    def author_url
      @author_url
    end
    def duration
      @duration
    end
    def size
      @size
    end
  end

  def is_source_allowed(source : String) : Bool
    config_get("songs.allow_all_sources").as?(Bool) || config_get("songs.sources.#{source}.allow").as?(Bool) || false
  end

  def get_file_path(song_id : Int32)
    Path.new("data", "#{song_id}.mp3")
  end

  # will raise errors
  def fetch_song_metadata(url : String) : SongMetadata
    LOG.info { "getting metadata for #{url}" }

    output = IO::Memory.new
    # todo: ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️ LOOK OUT FOR SHELL INJECTION BULLSHIT!!!!!!!!!!!!!!!!!!
    Process.run(config_get("songs.sources.ytdlp_binary").as?(String) || "yt-dlp", ["-J", url], output: output)
    output.close

    metadata = JSON.parse(output.to_s)

    canonical_url = metadata["webpage_url"].as_s? || metadata["original_url"].as_s? || url
    duration = metadata["duration"]? && (metadata["duration"].as_f? || metadata["duration"].as_i?)

    return SongMetadata.new(
      (metadata["fulltitle"]? && metadata["fulltitle"].as_s?) || (metadata["title"]? && metadata["title"].as_s?) || url,
      (metadata["uploader"]? && metadata["uploader"].as_s?) || "",
      canonical_url,
      metadata["extractor"].as_s,
      (metadata["uploader_url"]? && metadata["uploader_url"].as_s?) || canonical_url,
      duration ? duration.to_i : nil,
      metadata["filesize"]? && metadata["filesize"].as_i?
    )
  end

  def get_artist_id(artist_name : String, artist_url : String, source : String) : Int32
    if source == "unknown"
      return UNKNOWN_SONG_AUTHOR
    end
    if artist_name == ""
      return UNKNOWN_SONG_AUTHOR
    end

    begin
      DATABASE.query_one("select id from song_authors where name = ? and url = ? and source = ?", artist_name, artist_url, source, as: {Int32})
    rescue
      next_id = IDs.get_next_id("song_authors")
      DATABASE.exec("insert into song_authors (id, source, name, url) values (?, ?, ?, ?)", next_id, source, artist_name, artist_url)
      next_id.to_i
    end
  end

  # name, author id, author name, size, download url
  # returns nil if song should be disabled
  # throws if something failed
  def fetch_song(song_id : Int32, get_download = false) : Tuple(String, Int32, String, Int32 | Nil, String | Nil) | Nil
    LOG.debug { "fetching #{song_id}" }
    if !config_get("songs.allow_custom_songs").as?(Bool)
      return nil
    end

    # todo: this is kinda spaghetti
    metadata = nil
    author_id = nil
    fetch_url = nil

    song_exists = false
    url = nil

    begin
      url, disabled = DATABASE.query_one("select url, disabled from songs where id = ?", song_id, as: {String, Bool})

      if disabled
        return nil
      end

      song_exists = true
    rescue
      if config_get("songs.preserve_newgrounds_ids").as?(Bool)
        url = "https://www.newgrounds.com/audio/listen/#{song_id}"
      else
        raise "unknown song ID"
      end
    end

    if DATABASE.scalar("select count(*) from song_data where id = ?", song_id).as(Int64) > 0
      song_name, song_author_id, song_author_name, song_author_url, song_size, song_source, song_duration, download_url = DATABASE.query_one("select song_data.name, author_id, song_authors.name, song_authors.url, size, song_data.source, duration, proxy_url from song_data left join song_authors on song_authors.id = song_data.author_id where song_data.id = ?", song_id, as: {String, Int32, String?, String?, Int32?, String, Int32?, String?})

      fetch_url = download_url
      author_id = song_author_id
      metadata = SongMetadata.new(song_name, song_author_name || "", url.not_nil!, song_source, song_author_url || "", song_duration, song_size)
    else
      begin
        metadata = fetch_song_metadata(url.not_nil!)
      rescue err
        LOG.warn { "ran into error fetching metadata: #{err}; disabling song" }
        LOG.warn { err.inspect }
        if song_exists
          DATABASE.exec("update songs set disabled=1 where id = ?", song_id)
        else
          DATABASE.exec("insert into songs (id, url, disabled) values (?, ?, 1)", song_id, url)
        end
        return nil
      else
        if song_exists && url != metadata.normalized_url
          DATABASE.exec("update songs set url = ? where id = ?", metadata.normalized_url, song_id)
        end

        if DATABASE.scalar("select count(*) from songs join song_data on songs.id = song_data.id where songs.id != ? and url = ?", song_id, metadata.normalized_url).as(Int64) > 0
          # just use that song's metadata instead
          # todo: dedup this and the above similar block somehow?

          song_name, song_author_id, song_author_name, song_author_url, song_size, song_source, song_duration, download_url = DATABASE.query_all("select song_data.name, author_id, song_authors.name, song_authors.url, size, song_data.source, duration, proxy_url from song_data left join songs on song_data.id = songs.id left join song_authors on song_authors.id = song_data.author_id where song_data.id != ? and songs.url = ?", song_id, metadata.normalized_url, as: {String, Int32, String?, String?, Int32?, String, Int32?, String?})[0]

          fetch_url = download_url
          author_id = song_author_id
          metadata = SongMetadata.new(song_name, song_author_name || "", url.not_nil!, song_source, song_author_url || "", song_duration, song_size)
        end
      end
    end

    LOG.debug { metadata.inspect }

    # do checks to make sure this is a valid song
    max_duration = config_get("songs.sources.max_duration").as?(Int64)
    # todo

    if (fetch_url || !get_download) && metadata && author_id
      # we're done! woo
      if fetch_url && fetch_url.starts_with?("./")
        # todo
        fetch_url = "localhost:8080/#{fetch_url[2..]}"
      end
      return {metadata.name, author_id, metadata.author, metadata.size, fetch_url}
    end

    metadata = metadata.not_nil!
    new_size = nil

    if get_download
      if config_get("songs.sources.allow_transcoding")
        if !config_get("songs.sources.proxy_downloads").as?(Bool)
          raise "can't download a song with transcoding but without proxying allowed"
        end

        # todo: check if song file exists

        target_path = get_file_path(song_id)

        Process.run(config_get("songs.sources.ytdlp_binary").as?(String) || "yt-dlp", ["-f", "ba", "-x", "--audio-format", GD_AUDIO_FORMAT, "-o", target_path.to_s, "--ffmpeg-location", config_get("songs.sources.ffmpeg_binary").as?(String) || "ffmpeg", metadata.normalized_url], output: STDOUT, error: STDOUT)

        new_size = File.size(target_path).to_i

        # todo: get duration

        fetch_url = "./#{song_id}.mp3"
      else
        # todo
        raise "fetching songs without transcoding and proxying downloads currently unimplemented"
      end
    end

    if !author_id
      author_id = get_artist_id(metadata.author, metadata.source, metadata.author_url)
    end

    if config_get("songs.sources.proxy_downloads")
      if DATABASE.scalar("select count(*) from song_data where id = ?", song_id).as(Int64) > 0
        DATABASE.exec("update song_data set name = ?, author_id = ?, size = ? where id = ?", metadata.name, author_id, new_size || metadata.size, song_id)
      else
        DATABASE.exec("insert into song_data (id, name, author_id, source, size, duration, proxy_url) values (?, ?, ?, ?, ?, ?, ?)", song_id, metadata.name, author_id, metadata.source, metadata.size, metadata.duration, fetch_url)
      end
    else
      # todo
    end

    if fetch_url && fetch_url.starts_with?("./")
      # todo
      # todo also: deduplicate this with similar block above?
      fetch_url = "localhost:8080/#{fetch_url[2..]}"
    end
    return {metadata.name, author_id, metadata.author, new_size || metadata.size, fetch_url}
  end
end
