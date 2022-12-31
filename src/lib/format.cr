module CrystalGauntlet::Format
  extend self

  def fmt_value(v) : String
    case v
    when Bool
      v ? "1" : "0"
    when String
      v
    else
      v.to_s
    end
  end

  def fmt_hash(hash) : String
    hash.map_with_index{ |(i, v)| "#{i}:#{fmt_value(v)}" }.join(":")
  end
end

module CrystalGauntlet::GDBase64
  extend self

  def encode(v)
    Base64.encode(v).gsub('/', '_').gsub('+', '-').strip("\n")
  end

  def decode(v)
    Base64.decode(v.gsub('_', '/').gsub('-', '+'))
  end

  def decode_string(v)
    Base64.decode_string(v.gsub('_', '/').gsub('-', '+'))
  end
end

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
end
