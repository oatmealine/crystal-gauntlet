module CrystalGauntlet::PatchExe
  extend self

  SUPPORTED_PATCH_PLATFORMS = ["Windows"]
  SUPPORTED_EXTENSIONS = ["exe"]

  ROBTOP_SERVER_PATH = "http://www.boomlings.com/database"

  def robtop_server_path
    ROBTOP_SERVER_PATH
  end

  def full_server_path
    "http://" + config_get("general.hostname", "") + "/" + config_get("general.append_path", "").chomp("/")
  end

  def replace(from : IO, to : IO, search : Array(UInt8), replace : Array(UInt8))
    if search.size != replace.size
      raise "Search and replacement does not match in size"
    end

    size = search.size

    buffer = [] of UInt8

    replacements = 0

    from.each_byte do |byte|
      if buffer.size >= size
        insert_byte = buffer.shift
        to.write_byte(insert_byte)
      end

      buffer << byte

      if buffer == search
        replace.each() { |b| to.write_byte(b) }
        buffer = [] of UInt8
        replacements += 1
      end
    end

    buffer.each() { |b| to.write_byte(b) }

    replacements
  end

  def patch_exe_file(location : String)
    file_split = location.split(".")
    extension = file_split.pop
    patched_location = "#{file_split.join(".")}_patched.#{extension}"
    File.open("#{location}", "r") do |from|
      File.open(patched_location, "w") do |to|
        start = Time.monotonic

        amt = 0

        case extension
        when "exe"
          gd_temp = File.tempfile("GeometryDash")
          LOG.debug { "  #{robtop_server_path.colorize(:dark_gray)} ->" }
          LOG.debug { "  #{full_server_path.colorize(:dark_gray)}" }
          File.open(gd_temp.path, "w") do |tmp|
            amt += replace(from, tmp, robtop_server_path.bytes, full_server_path.bytes)
          end
          LOG.debug { "  #{Base64.strict_encode(robtop_server_path).colorize(:dark_gray)} ->" }
          LOG.debug { "  #{Base64.strict_encode(full_server_path).colorize(:dark_gray)}" }
          File.open(gd_temp.path, "r") do |tmp|
            amt += replace(tmp, to, Base64.strict_encode(robtop_server_path).bytes, Base64.strict_encode(full_server_path).bytes)
          end
          gd_temp.delete
        else
          LOG.error { "Unsupported extension #{extension.colorize(:white)} (supported: #{SUPPORTED_EXTENSIONS.join(", ")})" }
        end

        LOG.info { "Patched #{location} into #{patched_location} successfully" }
        LOG.info { "#{amt} replacements done in #{(Time.monotonic - start).total_seconds.humanize(precision: 2, significant: false)}s" }
      end
    end
  end

  def check_server_length(exit_if_fail : Bool)
    if full_server_path.size != robtop_server_path.size
      LOG.warn { "i think you made a mistake? length of full server path and default .exe location do not match" }
      LOG.warn { "  #{full_server_path}" }
      LOG.warn { "  #{robtop_server_path}" }
      min_length = Math.min(full_server_path.size, robtop_server_path.size)
      max_length = Math.max(full_server_path.size, robtop_server_path.size)
      LOG.warn { "  #{" " * min_length}#{"^" * (max_length - min_length)}"}

      if exit_if_fail
        exit 1
      end
    end
  end
end
