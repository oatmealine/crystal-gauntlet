module CrystalGauntlet::Format
  extend self

  TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
  # used when sending back to the client as an absolute date
  TIME_FORMAT_GD_FRIENDLY = "%d/%m/%Y %H.%M"
  # safe to send back in comments
  TIME_FORMAT_USER_FRIENDLY = "%d/%m/%Y %H:%M"

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

  def fmt_timespan_bit(n : Int, s : String) : String | Nil
    if n > 0
      return "#{n}#{s}"
    end
  end

  def fmt_timespan_long(s : Time::Span) : String
    [
      {s.days, "d"},
      {s.hours, "h"},
      {s.minutes, "m"},
      {s.seconds, "s"}
    ].map { |n, s| fmt_timespan_bit(n.floor().to_i, s) }.compact.join(" ")
  end

  def fmt_time(s : Time, colon_safe=false) : String
    s.to_s(colon_safe ? TIME_FORMAT_USER_FRIENDLY : TIME_FORMAT_GD_FRIENDLY)
  end

  def fmt_value(v, colon_safe=false, tilda_safe=false, pipe_safe=false) : String
    case v
    when Bool
      v ? "1" : "0"
    when Time::Span
      fmt_timespan(v)
    when Time
      if config_get("formatting.date") == "relative"
        fmt_timespan(Time.utc - v)
      else
        fmt_time(v, colon_safe)
      end
    when Nil
      ""
    else
      v = v.to_s
      v = Clean.clean_special(v)
      if !colon_safe
        v = v.gsub(":", "")
      end
      if !tilda_safe
        v = v.gsub("~", "")
      end
      if !pipe_safe
        v = v.gsub("|", "")
      end
      v
    end
  end

  def fmt_hash(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}:#{fmt_value(v, false, true, false)}" }.join(":")
  end

  def fmt_song(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}~|~#{fmt_value(v, true, false, false)}" }.join("~|~")
  end

  def fmt_comment(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}~#{fmt_value(v, false, false, true)}" }.join("~")
  end
end
