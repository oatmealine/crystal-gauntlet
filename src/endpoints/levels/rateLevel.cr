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

  vote_count = DATABASE.scalar("select count(*) from difficulty_votes where level_id = ?", level_id).as(Int64)

  # todo: make this configurable
  if vote_count > 0
    # todo: cache in some form?
    votes = DATABASE.query_all("select stars from difficulty_votes where level_id = ?", level_id, as: {Int32})
    avg = votes.sum() / votes.size
    difficulty = stars_to_difficulty(Int32.new(avg.round()))

    if difficulty
      DATABASE.exec("update levels set community_difficulty = ? where id = ?", difficulty.value, level_id)
    end
  end

  return "-1"
}
