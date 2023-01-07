require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/rateGJStars211.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  level_id = params["levelID"].to_i
  stars = params["stars"].to_i

  if stars > 10 || stars < 1
    return "-1"
  end

  # todo: implement this for mod accounts

  if DATABASE.scalar("select count(*) from levels where id = ?", level_id).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("insert into difficulty_votes (level_id, stars) values (?, ?)", level_id, stars)

  if config_get("voting.allow_votes").as(Bool | Nil) == false
    return "1"
  end

  vote_count = DATABASE.scalar("select count(*) from difficulty_votes where level_id = ?", level_id).as(Int64)

  min_votes = config_get("voting.min_votes").as(Int64 | Nil) || 1

  if vote_count >= min_votes
    # todo: cache in some form?
    votes = DATABASE.query_all("select stars from difficulty_votes where level_id = ?", level_id, as: {Int32})
    avg = votes.sum() / votes.size
    difficulty = stars_to_difficulty(Int32.new(avg.round()).clamp(2..9))

    if difficulty
      DATABASE.exec("update levels set community_difficulty = ? where id = ?", difficulty.value, level_id)
    end
  end

  return "1"
}

CrystalGauntlet.endpoints["/rateGJDemon21.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  level_id = params["levelID"].to_i
  rating = params["rating"].to_i

  if rating < 1 || rating > 5
    return "-1"
  end
  rating -= 1

  # todo: implement this for mod accounts

  if DATABASE.scalar("select count(*) from levels where id = ?", level_id).as(Int64) == 0
    return "-1"
  end

  DATABASE.exec("insert into demon_difficulty_votes (level_id, demon_difficulty) values (?, ?)", level_id, rating)

  if config_get("voting.allow_demon_votes").as(Bool | Nil) == false
    return level_id.to_s
  end

  vote_count = DATABASE.scalar("select count(*) from demon_difficulty_votes where level_id = ?", level_id).as(Int64)

  min_votes = config_get("voting.min_demon_votes").as(Int64 | Nil) || 1

  if vote_count >= min_votes
    # todo: cache in some form?
    votes = DATABASE.query_all("select demon_difficulty from demon_difficulty_votes where level_id = ?", level_id, as: {Int32})
    avg = votes.sum() / votes.size
    demon_difficulty = DemonDifficulty.new(Int32.new(avg.round()))

    if demon_difficulty
      DATABASE.exec("update levels set demon_difficulty = ? where id = ?", demon_difficulty.value, level_id)
    end
  end

  return level_id.to_s
}

CrystalGauntlet.endpoints["/rateGJStars20.php"] = CrystalGauntlet.endpoints["/rateGJStars211.php"]

CrystalGauntlet.endpoints["/rateGJStars.php"] = ->(context : HTTP::Server::Context): String {
  "-1"
}

CrystalGauntlet.endpoints["/rateGJLevel.php"] = ->(context : HTTP::Server::Context): String {
  "-1"
}

