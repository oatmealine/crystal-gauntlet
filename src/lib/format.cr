module CrystalGauntlet::Format
  extend self

  TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

  def fmt_timespan(s : Time::Span) : String
    seconds = s.total_seconds.floor()
    minutes = s.total_minutes.floor()
    hours = s.total_hours.floor()
    days = s.total_days.floor()
    months = (s.total_days / 30).floor()
    years = (s.total_days / 365).floor()
    case
    when months >= 17
      "#{years.to_i} year#{years == 1 ? "" : "s"}"
    when days >= 31
      "#{months.to_i} month#{months == 1 ? "" : "s"}"
    when hours >= 24
      "#{days.to_i} day#{days == 1 ? "" : "s"}"
    when minutes >= 60
      "#{hours.to_i} hour#{hours == 1 ? "" : "s"}"
    when seconds >= 60
      "#{minutes.to_i} minute#{minutes == 1 ? "" : "s"}"
    else
      "#{seconds.to_i} second#{seconds == 1 ? "" : "s"}"
    end
  end

  def fmt_value(v) : String
    case v
    when Bool
      v ? "1" : "0"
    when String
      v
    when Time::Span
      fmt_span(v)
    else
      v.to_s
    end
  end

  def fmt_hash(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}:#{fmt_value(v)}" }.join(":")
  end

  def fmt_song(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}~|~#{fmt_value(v)}" }.join("~|~")
  end
end

module CrystalGauntlet::GDBase64
  extend self

  def encode(v)
    Base64.encode(v).gsub('/', '_').gsub('+', '-').strip("\n")
  end

  def decode(v)
    Base64.decode(v.gsub('_', '/').gsub('-', '+'))
  end

  def decode_string(v)
    Base64.decode_string(v.gsub('_', '/').gsub('-', '+'))
  end
end

module CrystalGauntlet::XorCrypt
  extend self

  def encrypt(x : Bytes, key : Bytes) : Bytes
    result = Bytes.new(x.size)
    x.each.with_index() do |chr, index|
      result[index] = (chr ^ key[index % key.size])
    end
    result
  end

  def encrypt_string(x : String, key : String) : Bytes
    result = Bytes.new(x.bytesize)
    x.bytes.each.with_index() do |chr, index|
      result[index] = (chr ^ key.byte_at(index % key.bytesize))
    end
    result
  end
end
