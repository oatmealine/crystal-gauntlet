require "crypto/bcrypt/password"
require "base64"

module CrystalGauntlet::GJP
  extend self

  XOR_KEY = "37526"

  def decrypt(pass : String)
    pwd = Base64.decode_string(pass.sub('_', '/').sub('-', '+'))
    decrypted = ""

    pwd.each.with_index() do |chr, index|
      decrypted += (chr ^ XOR_KEY.byte_at(index % XOR_KEY.bytesize)).unsafe_chr
    end

    decrypted
  end

  def encrypt(pass : String)
    encrypted = Bytes.new(pass.bytesize)

    pass.bytes.each.with_index() do |chr, index|
      encrypted[index] = chr ^ XOR_KEY.byte_at(index % XOR_KEY.bytesize)
    end

    Base64.encode(encrypted).sub('/', '_').sub('+', '-')
  end

  def hash(pass : String)
    gjp2_hash = Digest::SHA1.hexdigest(pass + "mI29fmAnxgTs")
    Crypto::Bcrypt::Password.create(gjp2_hash, cost: 10).to_s
  end
end
