module CrystalGauntlet::XorCrypt
  extend self

  def encrypt(x : Bytes, key : Bytes) : Bytes
    result = Bytes.new(x.size)
    x.each.with_index() do |chr, index|
      result[index] = (chr ^ key[index % key.size])
    end
    result
  end

  def encrypt_string(x : String, key : String) : Bytes
    result = Bytes.new(x.bytesize)
    x.bytes.each.with_index() do |chr, index|
      result[index] = (chr ^ key.byte_at(index % key.bytesize))
    end
    result
  end

  QUESTS_XOR_KEY = "19847"
  CHEST_XOR_KEY = "59182"
  MESSAGE_XOR_KEY = "14251"
end
