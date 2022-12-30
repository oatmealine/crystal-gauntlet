require "digest/sha1"
require "crypto/bcrypt"

module CrystalGauntlet::Hashes
  extend self

  def gen_multi(level_hash_data : Array(Tuple(Int32, Int32, Bool)))
    Digest::SHA1.hexdigest do |ctx|
      level_hash_data.each.with_index() do |val, index|
        level_id, stars, coins = val
        level_id_str = level_id.to_s
        ctx.update "#{level_id_str[0]}#{level_id_str[-1]}#{stars}#{coins ? 1 : 0}"
      end

      ctx.update "xI25fpAapCQg"
    end
  end

  def gen_solo(level_string : String) : String
    hash = ""
    divided : Int32 = (level_string.size / 40).to_i
    i = 0
    k : Int32 = 0
    while k < level_string.size
      if i > 39
        break
      end

      hash += level_string.char_at(k)
      i += 1
      k += divided
    end
    Digest::SHA1.hexdigest(hash.ljust(5, 'a') + "xI25fpAapCQg")
  end

  def gen_solo_2(level_multi_string : String) : String
    Digest::SHA1.hexdigest do |ctx|
      ctx.update level_multi_string
      ctx.update "xI25fpAapCQg"
    end
  end

  def gen_solo_3(level_multi_string : String) : String
    Digest::SHA1.hexdigest do |ctx|
      ctx.update level_multi_string
      ctx.update "oC36fpYaPtdg"
    end
  end

  def gen_solo_4(level_multi_string : String) : String
    Digest::SHA1.hexdigest do |ctx|
      ctx.update level_multi_string
      ctx.update "pC26fpYaQCtg"
    end
  end
end
