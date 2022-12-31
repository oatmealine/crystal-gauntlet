module CrystalGauntlet
  enum LevelLength
    Tiny
    Short
    Medium
    Long
    XL
  end

  enum LevelDifficulty
    Auto
    Easy
    Normal
    Hard
    Harder
    Insane
    Demon

    def to_star_difficulty
      case self
      when .auto?
        50
      when .easy?
        10
      when .normal?
        20
      when .hard?
        30
      when .harder?
        40
      when .insane?
        50
      when .demon?
        50
      end
    end
  end

  def stars_to_difficulty(stars : Int32) : LevelDifficulty | Nil
    case stars
    when 1
      LevelDifficulty::Auto
    when 2
      LevelDifficulty::Easy
    when 3
      LevelDifficulty::Normal
    when 4, 5
      LevelDifficulty::Hard
    when 6, 7
      LevelDifficulty::Harder
    when 8, 9
      LevelDifficulty::Insane
    when 10
      LevelDifficulty::Demon
    else
      nil
    end
  end

  enum DemonDifficulty
    Easy
    Medium
    Hard
    Insane
    Extreme
    # unsafe
    #Tarsorado

    def to_demon_difficulty
      case self
      when .easy?
        3
      when .medium?
        4
      when .hard?
        0
      when .insane?
        5
      when .extreme?
        6
      end
    end
  end
end
