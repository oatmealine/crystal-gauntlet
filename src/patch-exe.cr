require "file_utils"

module CrystalGauntlet::PatchExe
  extend self

  SUPPORTED_PATCH_PLATFORMS = ["Windows", "Android"]
  SUPPORTED_EXTENSIONS = ["exe", "apk"]

  ROBTOP_SERVER_PATH = "http://www.boomlings.com/database"

  def robtop_server_path
    ROBTOP_SERVER_PATH
  end

  def full_server_path
    "http://" + config_get("general.hostname", "") + "/" + config_get("general.append_path", "").chomp("/")
  end

  def replace(from : IO, to : IO, search : Array(UInt8), replace : Array(UInt8))
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

  def force_rm(path : Path)
    Dir.each_child(path) do |file|
      if File.info(path / file).directory?
        force_rm(path / file)
      else
        FileUtils.rm(path / file)
      end
    end
  end

  def patch_exe_file(location : String, new_package_name : String?)
    file_split = location.split(".")
    extension = file_split.pop
    patched_location = "#{file_split.join(".")}_patched.#{extension}"
    start = Time.monotonic

    amt = 0

    case extension
    when "exe"
      gd_temp = File.tempfile("GeometryDash")
      File.open(location, "r") do |from|
        LOG.debug { "  #{robtop_server_path.colorize(:dark_gray)} ->" }
        LOG.debug { "  #{full_server_path.colorize(:dark_gray)}" }
        File.open(gd_temp.path, "w") do |tmp|
          amt += replace(from, tmp, robtop_server_path.bytes, full_server_path.bytes)
        end
      end
      File.open(patched_location, "w") do |to|
        LOG.debug { "  #{Base64.strict_encode(robtop_server_path).colorize(:dark_gray)} ->" }
        LOG.debug { "  #{Base64.strict_encode(full_server_path).colorize(:dark_gray)}" }
        File.open(gd_temp.path, "r") do |tmp|
          amt += replace(tmp, to, Base64.strict_encode(robtop_server_path).bytes, Base64.strict_encode(full_server_path).bytes)
        end
      end
      gd_temp.delete
    when "apk"
      apktool = Process.find_executable("apktool")
      if !apktool
        LOG.error { "apktool not found! Please put this somewhere in your path: https://ibotpeaches.github.io/Apktool/" }
        return
      end
      LOG.info { "Using apktool in #{apktool}" }

      tmpdir = Path.new(Dir.tempdir, "#{location.split("/").last}_unpacked")
      Process.run(apktool, ["d", location, "-o", tmpdir.to_s, "-f"], output: STDOUT, error: STDERR)

      gd_temp = File.tempfile("libcocos2dcpp")
      File.open(tmpdir / "lib" / "armeabi" / "libcocos2dcpp.so", "r") do |from|
        LOG.debug { "  #{robtop_server_path.colorize(:dark_gray)} ->" }
        LOG.debug { "  #{full_server_path.colorize(:dark_gray)}" }
        File.open(gd_temp.path, "w") do |tmp|
          amt += replace(from, tmp, robtop_server_path.bytes, full_server_path.bytes)
        end
      end
      File.open(tmpdir / "lib" / "armeabi" / "libcocos2dcpp.so", "w") do |to|
        LOG.debug { "  #{Base64.strict_encode(robtop_server_path).colorize(:dark_gray)} ->" }
        LOG.debug { "  #{Base64.strict_encode(full_server_path).colorize(:dark_gray)}" }
        File.open(gd_temp.path, "r") do |tmp|
          amt += replace(tmp, to, Base64.strict_encode(robtop_server_path).bytes, Base64.strict_encode(full_server_path).bytes)
        end
      end
      gd_temp.delete

      if new_package_name
        LOG.info { "Changing package name to #{new_package_name}" }
        FileUtils.mv(tmpdir / "apktool.yml", tmpdir / "apktool_.yml")
        File.open(tmpdir / "apktool_.yml", "r") do |from|
          File.open(tmpdir / "apktool.yml", "w") do |to|
            replace(from, to, "renameManifestPackage: null".bytes, "renameManifestPackage: #{new_package_name}".bytes)
          end
        end
        FileUtils.rm(tmpdir / "apktool_.yml")
      else
        LOG.warn { "No new package name specified - this will not install properly if vanilla GD is installed" }
      end

      Process.run(apktool, ["b", tmpdir.to_s, "-o", patched_location, "-f"], output: STDOUT, error: STDERR)

      force_rm(tmpdir)

      LOG.notice { "This will not install properly - you need to sign it with jarsigner: https://docs.oracle.com/javase/9/tools/jarsigner.htm" }
    else
      LOG.error { "Unsupported extension #{extension.colorize(:white)} (supported: #{SUPPORTED_EXTENSIONS.join(", ")})" }
    end

    LOG.info { "Patched #{location} into #{patched_location} successfully" }
    LOG.info { "#{amt} replacements done in #{(Time.monotonic - start).total_seconds.humanize(precision: 2, significant: false)}s" }
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
