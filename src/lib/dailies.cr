include CrystalGauntlet

module CrystalGauntlet::Dailies
  extend self

  # todo: merge the two tables into one maybe

  WEEKLY_OFFSET = 100001

  def grab_new_level(weekly : Bool, prev = Time.utc, prev_idx = 0) : {Int32?, Int32?, Int32?}
    LOG.debug { "grabbing new event level, weekly: #{weekly} (previous queue index #{prev_idx})" }

    begin
      level_id, new_idx = DATABASE.query_one("select level_id, idx from #{weekly ? "weekly_queue" : "daily_queue"} where idx > #{prev_idx} order by idx limit 1", as: {Int32, Int32})
    rescue
      LOG.debug { "can't find new level in queue, attempting reuse" }
      begin
        level_id, new_idx = DATABASE.query_one("select level_id, idx from #{weekly ? "weekly_queue" : "daily_queue"} order by idx desc limit 1", as: {Int32, Int32})
      rescue
        LOG.debug { "no levels in queue; quitting out" }
        return {nil, nil, nil}
      end
    end

    next_id = IDs.get_next_id(weekly ? "weekly_levels" : "daily_levels")
    # todo: configurable?
    timespan = weekly ? 1.weeks : 1.days
    LOG.debug { "#{level_id} for #{timespan}" }
    expires_at = prev + timespan
    DATABASE.exec("insert into #{weekly ? "weekly_levels" : "daily_levels"} (level_id, idx, expires_at, queue_idx) values (?, ?, ?, ?)", level_id, next_id, expires_at.to_s(Format::TIME_FORMAT), new_idx)

    return {level_id, timespan.total_seconds.to_i, next_id}
  end

  def fetch_current_level(weekly : Bool) : {Int32 | Nil, Int32 | Nil, Int32 | Nil}
    LOG.debug { "getting current event level, weekly: #{weekly}" }
    begin
      level_id, expires_at, idx, queue_idx = DATABASE.query_one("select level_id, expires_at, idx, queue_idx from #{weekly ? "weekly_levels" : "daily_levels"} order by idx desc limit 1", as: {Int32, String, Int32, Int32})
      LOG.debug { "#{level_id} (#{idx}), expiring at #{expires_at}" }
    rescue
      # make up a brand new daily; using current time because no previous ones have existed
      LOG.debug { "no levels have ever existed" }
      level_id, expires, idx = grab_new_level(weekly)
    else
      # check if it has expired, roll a new one if so
      expires = (Time.parse(expires_at, Format::TIME_FORMAT, Time::Location::UTC) - Time.utc).total_seconds.to_i
      if expires <= 0
        LOG.debug { "expired!!" }
        level_id, expires, idx = grab_new_level(weekly, Time.parse(expires_at, Format::TIME_FORMAT, Time::Location::UTC), queue_idx)
      end
    end

    LOG.debug { "returning #{level_id} #{idx}, expiring in #{expires}s" }

    return level_id, expires, idx
  end
end
