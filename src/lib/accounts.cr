require "uri"
require "crypto/bcrypt/password"

include CrystalGauntlet

module CrystalGauntlet::Accounts
  extend self

  def get_account_id_from_params(params : URI::Params) : Int32 | Nil
    if params["accountID"]? && params["accountID"]? != "0"
      # todo: validate password
      params["accountID"].to_i32
    else
      nil
    end
  end

  def get_ext_id_from_params(params : URI::Params) : String | Nil
    return "1"
    if params.has_key?("udid") && params["udid"] != ""
      # todo: numeric id check
      params["udid"]
    elsif params.has_key?("accountID") && params["accountID"] != "" && params["accountID"] != "0"
      # todo: validate password
      params["accountID"]
    else
      nil
    end
  end

  def get_user_id(ext_id : String) : Int32
    DATABASE.query("select id from users where udid = ? or account_id = ?", ext_id, ext_id) do |rs|
      if rs.move_next
        return rs.read(Int32)
      else
        raise "no user associated with account?!"
      end
    end
  end

  def verify_gjp(account_id : Int32, gjp : String) : Bool
    hash = DATABASE.scalar("select password from accounts where id = ?", account_id).as(String)
    bcrypt = Crypto::Bcrypt::Password.new(hash)
    bcrypt.verify(GJP.decrypt(gjp))
  end
end
