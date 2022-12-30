require "uri"

include CrystalGauntlet

module CrystalGauntlet::Accounts
  extend self

  def get_ext_id_from_params(params : URI::Params) : String
    return "1"
    if params.has_key?("udid") && params["udid"] != ""
      # todo: numeric id check
      params["udid"]
    elsif params.has_key?("account_id") && params["account_id"] != "" && params["account_id"] != "0"
      # todo: validate password
      params["account_id"]
    else
      "-1"
    end
  end

  def get_user_id(username : String, ext_id : String) : Int32
    return 1
    DATABASE.query("select id from users where udid = ? or account_id = ?", ext_id, ext_id) do |rs|
      if rs.column_count > 0
        return rs.read(Int32)
      else
        raise "no user associated with account?!"
      end
    end
  end
end
