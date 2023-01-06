require "uri"
require "crypto/bcrypt/password"

include CrystalGauntlet

module CrystalGauntlet::Accounts
  extend self

  # DOESN'T VERIFY PASSWORD
  def get_account_id_from_params(params : URI::Params) : Int32 | Nil
    if params["accountID"]? && params["accountID"]? != "0"
      params["accountID"].to_i32
    else
      nil
    end
  end

  # DOESN'T VERIFY PASSWORD
  def get_ext_id_from_params(params : URI::Params) : Int32 | Nil
    if params.has_key?("udid") && !params["udid"].blank?
      params["udid"].to_i32?
    else
      get_account_id_from_params(params)
    end
  end

  # todo: clean this periodically
  AUTH_CACHE = Hash(Tuple(String | Nil, String | Nil, String | Nil), Tuple(Int32, Int32) | Tuple(Nil, Nil)).new

  # returns userid, accountid
  def auth(params : URI::Params) : (Tuple(Int32, Int32) | Tuple(Nil, Nil))
    gjp = params["gjp"]?
    udid = params["udid"]?
    account_id = params["accountID"]?

    if AUTH_CACHE[{gjp, udid, account_id}]?
      LOG.debug {"#{account_id || udid || "???"}: gjp cache hit"}
      return AUTH_CACHE[{gjp, udid, account_id}]
    end
    LOG.debug {"#{account_id || udid || "???"}: gjp cache miss"}

    ext_id = Accounts.get_account_id_from_params(params)
    if !ext_id || !Accounts.verify_gjp(ext_id.to_i, gjp || "")
      return nil, nil
    end
    user_id = Accounts.get_user_id(ext_id)
    if !user_id
      return nil, nil
    end

    AUTH_CACHE[{gjp, udid, account_id}] = {user_id, ext_id.to_i}
    return user_id, ext_id.to_i
  end

  def get_user_id(ext_id : Int32) : Int32
    DATABASE.query("select id from users where udid = ? or account_id = ?", ext_id, ext_id) do |rs|
      if rs.move_next
        return rs.read(Int32)
      else
        raise "no user associated with account?!"
      end
    end
  end

  def verify_gjp(account_id : Int32, gjp : String) : Bool
    if gjp.blank?
      return false
    end
    hash = DATABASE.scalar("select password from accounts where id = ?", account_id).as(String)
    bcrypt = Crypto::Bcrypt::Password.new(hash)
    bcrypt.verify(GJP.decrypt(gjp))
  end

  def are_friends(account_id_1 : Int32, account_id_2 : Int32)
    DATABASE.scalar("select count(*) from friend_links where (account_id_1 = ? and account_id_2 = ?) or (account_id_2 = ? and account_id_1 = ?)", account_id_1, account_id_2, account_id_1, account_id_2).as(Int64) > 0
  end
end
