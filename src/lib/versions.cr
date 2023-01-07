require "semantic_version"

module CrystalGauntlet::Versions
  extend self

  def parse(game_version : String) : SemanticVersion
    n = game_version.to_i
    case n
    when (1..7).includes?(n)
      SemanticVersion.new(1, n - 1, 0)
    when 10
      SemanticVersion.new(1, 7, 0)
    else
      SemanticVersion.new(game_version[0].to_i, game_version[1].to_i, game_version[2..].to_i)
    end
  end

  def parse_binary(binary_version : String) : SemanticVersion
    n = binary_version.to_i
    # these aren't 100% accurate because binary_version
    # doesn't fully represent the version early on
    case n
    when 0
      SemanticVersion.new(1, 0, 0)
    when 1
      SemanticVersion.new(1, 1, 0)
    when 2
      SemanticVersion.new(1, 2, 0)
    when 3
      SemanticVersion.new(1, 3, 0)
    when 5
      SemanticVersion.new(1, 4, 0)
    when 6
      SemanticVersion.new(1, 5, 0)
    when 7
      SemanticVersion.new(1, 6, 0)
    when 10
      SemanticVersion.new(1, 7, 0)
    when 11
      SemanticVersion.new(1, 7, 1)
    when 12
      SemanticVersion.new(1, 8, 0)
    when 13
      SemanticVersion.new(1, 8, 1)
    when 14
      SemanticVersion.new(1, 8, 11)
    when 20
      SemanticVersion.new(1, 9, 0)
    when 24
      SemanticVersion.new(1, 9, 2)
    when 25
      SemanticVersion.new(1, 9, 3)
    when 27
      SemanticVersion.new(2, 0, 0)
    when 28
      SemanticVersion.new(2, 0, 1)
    when 29
      SemanticVersion.new(2, 0, 10)
    when 33
      SemanticVersion.new(2, 1, 0)
    when 34
      SemanticVersion.new(2, 1, 1)
    when 35
      SemanticVersion.new(2, 1, 13)
    else
      SemanticVersion.new(2, 1, 13)
    end
  end

  # shorthands because i hate typing 3 words for this
  V1_0 = SemanticVersion.new(1, 0, 0)
  V1_1 = SemanticVersion.new(1, 1, 0)
  V1_2 = SemanticVersion.new(1, 2, 0)
  V1_3 = SemanticVersion.new(1, 3, 0)
  V1_4 = SemanticVersion.new(1, 4, 0)
  V1_5 = SemanticVersion.new(1, 5, 0)
  V1_6 = SemanticVersion.new(1, 6, 0)
  V1_7 = SemanticVersion.new(1, 7, 0)
  V1_8 = SemanticVersion.new(1, 8, 0)
  V1_9 = SemanticVersion.new(1, 9, 0)
  V2_0 = SemanticVersion.new(2, 0, 0)
  V2_1 = SemanticVersion.new(2, 1, 0)
  V2_11 = SemanticVersion.new(2, 1, 1)
  V2_2 = SemanticVersion.new(2, 2, 0)
end
