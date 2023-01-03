require "compress/zlib"

include Compress

# module for general level decoding, parsing and encoding
module CrystalGauntlet::Level
  extend self

  # security.webm
  TEST_STRING = "H4sIAAAAAAAAC61Xy5HYIAxtyLuDJCTB5JQatgAKSAspPvxssC1lc8jBZngPhNAP-PVF6YASpWBhKlQkFoCCzAVwNNSbWD6gSIEQQtECBbj9UgklFfgNtcX6Uf2-mQ7udAhYxuhvRGRTRBszJvyTkLrfYusyBAE2Qe3_jSD-X4LEEXT8-gl0hNbwaGQ08ah_OaB1dECzSa35otx72P9DQid-xv4fbJ3dGzjCDzhAYzzwoHDQAbyA3IDYgdoD4qtL1HiQhmj91dU-ucIHNDbCTmIl8MB46JjZydxICHOq9rldlUAXLXlMCBVB7BMApjLViLtumDpdl8QmI8SuRlhMTEe1WRpLILbdxqnCpXGkKaQh0BCBU-xLzS7j4iuEXfM1oyr8IW3bH7TPPjcg-_Ktr6dFth0MkYNRWDuoqAZjfMPJwcWTPyXt8gdOb7zvWofzaNipxcnYdO5AMzoE2UyJHUm6mWpCp602u5xTL8NAyPaOANAj2COSQyB4RPQIfahJjkNqAHuE5ZJOGDvGsK_ysFnEhzLRs0D0LMCWBYa_gZGW-JGg3LefX8EEHF_ELAdh1IOKpFE88i2FZx-2RUScRYQ8IryIUT9A-WGiCWzLaXKkKjpEAo94W2ESL7uR9IIXljFmCRxbOdXN-a5_zSHbkxgc32MwfI8hbNQ9rBCcrEBwsgLBqmK9fIeH-uhkBaKTFYhGVkTdhMsqzw0lz0DkGYic5MDoGSJahuj-w1gLZ6Uwr_MUuSuKtUbK8ZEvTQc8CypRn86yYRuQ-R7cfbA88v8EZAHpyr4ecKh6P0D3PvZz8xlwacvXljwXpNeQjGPI00yZHTy98Sl6iFKTYp9Kb6rfbMBUgEJ0cH3jYWPydSNYi89FLL3mOjaltsoQbNX2a1jvizMue7adok1thnSbEp_K9h7QjgdCOx4I3_EgEpakRNtVM2wKoBstcy2bcqKFnGghJ1rIiJa5BPkxQX5MkBMTlLNTbirVyk3aLmtTVjTc1nE0ZI17sUGcwhxHRydYIzm4E7TRD9roR2Y04nmtsmroFN9i3BBinTu3bd85yuMVgfrZSOFP5A2OaMJsj1Z7dLqPPtVh6wA7OefUI07G3teMty_YSVJ2i_acYvqI_QxlJw3nVgyN2XcjG2f4NCcH08oMpk-Y7NHRHi326DxggNjef_sDjsS5VJA4tysy34hL1NtV4hQs8QuW-AVLjKp0Uu9aNi0gYdgr3Qxwkoh_IelvM8V0gyTTDZIfidRAdWqWOjXLe3GT9-Qm883dCetJO02pfp1T_9xW_3DWd82eZlEwraV2SVO7pKld0tQuafosaUv5daVRzU8P1IOvEmm-2Wo0jNszmijRwHv9qGrsGBtY2rBxmibQ_TT9A3vViWgxFQAA"

  # typically, you'd start right here
  def decode(level_data : String)
    io = IO::Memory.new(Base64.decode(level_data))
    decompress(io)
  end
  def decompress(level_data : IO)
    Gzip::Reader.open(level_data, true) do |io|
      parse(io.gets_to_end)
    end
  end

  def array_to_hash(arr : Array(String)) : Hash(String, String)
    key = nil
    hash = Hash(String, String).new
    arr.each() do |val|
      if key == nil
        key = val
      else
        hash[key.not_nil!] = val
        key = nil
      end
    end
    return hash
  end
  def parse(raw_level_data : String) : Array(Hash(String, String))
    objects = raw_level_data.chomp(";").split(";")
      .map { |v| array_to_hash(v.split(",")) }

    return objects
  end
end
