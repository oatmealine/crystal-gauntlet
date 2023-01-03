include CrystalGauntlet

module CrystalGauntlet::Dailies
  extend self

  # todo: merge the two tables into one maybe

  WEEKLY_OFFSET = 100001

  def grab_new_level(weekly : Bool, prev = Time.utc) : {Int32 | Nil, Int32 | Nil, Int32 | Nil}
    begin
      level_id = DATABASE.query_one("select level_id from #{weekly ? "weekly_queue" : "daily_queue"} order by idx desc limit 1", as: {Int32})
    rescue
      return {nil, nil, nil}
    else
      next_id = IDs.get_next_id(weekly ? "weekly_levels" : "daily_levels")
      # todo: configurable?
      timespan = weekly ? 1.weeks : 1.days
      expires_at = prev + timespan
      DATABASE.exec("insert into #{weekly ? "weekly_levels" : "daily_levels"} (level_id, idx, expires_at) values (?, ?, ?)", level_id, next_id, expires_at.to_s(Format::TIME_FORMAT))
      return {level_id, timespan.total_seconds.to_i, next_id}
    end
  end

  def fetch_current_level(weekly : Bool) : {Int32 | Nil, Int32 | Nil, Int32 | Nil}
    begin
      level_id, expires_at, idx = DATABASE.query_one("select level_id, expires_at, idx from #{weekly ? "weekly_levels" : "daily_levels"} order by idx desc limit 1", as: {Int32, String, Int32})
    rescue
      # make up a brand new daily; using current time because no previous ones have existed
      level_id, expires, idx = grab_new_level(weekly)
    else
      # check if it has expired, roll a new one if so
      expires = (Time.parse(expires_at, Format::TIME_FORMAT, Time::Location::UTC) - Time.utc).total_seconds.to_i
      if expires <= 0
        level_id, expires, idx = grab_new_level(weekly, Time.parse(expires_at, Format::TIME_FORMAT, Time::Location::UTC))
      end
    end

    return level_id, expires, idx
  end
end
