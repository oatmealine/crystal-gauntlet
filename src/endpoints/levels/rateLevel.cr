require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/rateGJStars211.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  level_id = params["levelID"].to_i
  # todo: clamp this
  stars = params["stars"].to_i

  # todo: implement this for mod accounts

  if DATABASE.scalar("select count(*) from levels where id = ?", level_id).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("insert into difficulty_votes (level_id, stars) values (?, ?)", level_id, stars)

  if config_get("voting.allow_votes").as(Bool | Nil) == false
    return "1"
  else
    vote_count = DATABASE.scalar("select count(*) from difficulty_votes where level_id = ?", level_id).as(Int64)

    min_votes = config_get("voting.min_votes").as(Int32 | Nil) || 0

    # todo: make this configurable
    if vote_count >= min_votes
      # todo: cache in some form?
      votes = DATABASE.query_all("select stars from difficulty_votes where level_id = ?", level_id, as: {Int32})
      avg = votes.sum() / votes.size
      difficulty = stars_to_difficulty(Int32.new(avg.round()))

      if difficulty
        DATABASE.exec("update levels set community_difficulty = ? where id = ?", difficulty.value, level_id)
      end
    end
  end

  # todo: remove (here for debugging)
  return "-1"
}
