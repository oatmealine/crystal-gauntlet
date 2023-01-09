module CrystalGauntlet::Ranks
  extend self

  class Rank
    getter name : String
    getter position : Int64 = 0
    getter badge : Int64 = 0
    getter is_mod : Bool = false
    getter text_color : Array(Int64)? = nil
    getter permissions : Hash(String, Bool) = Hash(String, Bool).new

    def initialize(@name, @position = 0, @badge = 0, @is_mod = false, @text_color = nil, @permissions = Hash(String, Bool).new)
    end

    def has_permission(key : String)
      @permissions[key]? || false
    end
  end

  NULL_RANK = Rank.new(name: "null", position: -1)

  @@ranks = [] of Rank

  def init()
    config_get("ranks").as(Hash(String, TOML::Type)).each() do |key, value_|
      value = value_.as(Hash(String, TOML::Type))
      perms = value["permissions"]?.as?(Hash(String, TOML::Type)) || Hash(String, Bool).new
      color = value["text_color"]?.as?(Array(TOML::Type))
      @@ranks << Rank.new(
        name: key,
        position: value["position"].as(Int64),
        badge: value["badge"]?.as?(Int64) || 0_i64,
        is_mod: value["is_mod"]?.as?(Bool) || false,
        text_color: color ? color.map { |v| v.as(Int64) } : nil,
        permissions: perms.transform_values { |v| v.as?(Bool) || false }
      )
    end

    if @@ranks.empty?
      LOG.error { "Ranks are empty! Things might go very, very wrong" }
    end

    @@ranks.sort! { |a, b| a.position <=> b.position }
  end

  def get_rank(rank_name : String) : Rank?
    @@ranks.find { |r| r.name == rank_name }
  end

  def get_rank(account_id : Int32) : Rank
    begin
      rank_name = DATABASE.query_one("select rank from accounts where id = ?", account_id, as: {String})
    rescue
      rank_name = "everyone"
    end

    get_rank(rank_name) || @@ranks[0]? || NULL_RANK
  end

  def get_permissions(rank : Rank) : Hash(String, Bool)
    prev_ranks = @@ranks.select { |i| i.position < rank.position }
    prev_ranks << rank
    prev_ranks.reduce(Hash(String, Bool).new(false)) { |a, b| a.merge(b.permissions) }
  end

  def get_permissions(account_id : Int32)
    get_permissions(get_rank(account_id))
  end

  def has_permission(rank : Rank, perm : String)
    get_permissions(rank)[perm]? || false
  end
  def has_permission(account_id : Int32, perm : String)
    get_permissions(account_id)[perm]? || false
  end
end
