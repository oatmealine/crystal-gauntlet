module CrystalGauntlet::CreatorPoints
  extend self

  QUERIES = StaticArray[
    {"select count(*) from levels where user_id = ? and stars is not null", "levels.creator_points.rated"},
    {"select count(*) from levels where user_id = ? and featured = 1", "levels.creator_points.featured"},
    {"select count(*) from levels where user_id = ? and epic = 1", "levels.creator_points.epic"},
    {"select count(*) from daily_levels join levels on levels.id = level_id where levels.user_id = ?", "levels.creator_points.daily"},
    {"select count(*) from weekly_levels join levels on levels.id = level_id where levels.user_id = ?", "levels.creator_points.weekly"},
    {"select count(*) from map_pack_links join levels on levels.id = level_id where levels.user_id = ?", "levels.creator_points.mappack"},
    {"select count(*) from gauntlet_links join levels on levels.id = level_id where levels.user_id = ?", "levels.creator_points.gauntlet"},
  ]

  def calculate_creator_points(user_id : Int32)
    QUERIES
      .map { |q, c| DATABASE.scalar(q, user_id).as(Int64) * config_get(c, 0_i64) }
      .sum()
  end

  def update_creator_points(user_id : Int32)
    points = calculate_creator_points(user_id)
    DATABASE.exec("update users set creator_points = ? where id = ?", points, user_id)
    return points
  end
end
