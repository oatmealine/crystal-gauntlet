require "json"

include CrystalGauntlet

module CrystalGauntlet::Songs
  extend self

  GD_AUDIO_FORMAT = "mp3"

  def is_custom_song(id)
    id >= 50
  end

  def is_reuploaded_song(id)
    id >= 5000000
  end

  class Song
    def initialize(name : String, author : String, size : Int32, download_url : String | Nil, normalized_url : String)
      @name = name
      @author = author
      @size = size
      @download_url = download_url
    end
  end

  def is_source_allowed(source : String) : Bool
    config_get("songs.allow_all_sources").as?(Bool) || config_get("songs.sources.#{source}.allow").as?(Bool) || false
  end

  def reupload(url : String, id : Int32) : Song | Nil
    puts url

    output = IO::Memory.new
    # todo: ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️ LOOK OUT FOR SHELL INJECTION BULLSHIT!!!!!!!!!!!!!!!!!!
    Process.run(config_get("songs.sources.ytdlp_binary").as?(String) || "yt-dlp", ["-J", url], output: output)
    output.close

    puts output.to_s

    metadata = JSON.parse(output.to_s)

    if !is_source_allowed(metadata["extractor"].as_s? || "unknown")
      raise "source forbidden: #{metadata["extractor"]}"
    end

    max_duration = config_get("songs.sources.max_duration").as?(Int64) || 0

    if max_duration > 0
      if !metadata["duration"]
        raise "failed to determine track duration"
      elsif metadata["duration"].as_f >= max_duration
        raise "track goes above max track duration (#{max_duration}s)"
      end
    end

    if config_get("songs.sources.allow_transcoding")
      if !config_get("songs.sources.proxy_downloads").as?(Bool)
        raise "can't download a song with transcoding but without proxying allowed"
      end

      canonical_url = metadata["webpage_url"].as_s? || metadata["original_url"].as_s? || url

      target_path = Path.new("data", "#{id}.mp3")

      Process.run(config_get("songs.sources.ytdlp_binary").as?(String) || "yt-dlp", ["-f", "ba", "-x", "--audio-format", GD_AUDIO_FORMAT, "-o", target_path.to_s, "--ffmpeg-location", config_get("songs.sources.ffmpeg_binary").as?(String) || "ffmpeg", canonical_url], output: STDOUT, error: STDOUT)

      size = File.size(target_path)

      # todo: don't point to localhost
      Song.new(metadata["fulltitle"].as_s? || metadata["title"].as_s? || "Song", metadata["uploader"].as_s? || "", size.to_i32, "http://localhost:8080/#{id}.mp3", canonical_url)
    else
      # todo
    end
  end
end
