require "json"

include CrystalGauntlet

module CrystalGauntlet::Notifications
  extend self

  alias NotificationDetails = Hash(String, String | Int64 | Bool | Float64 | Nil)

  def clear_previous_notifications(account_id : Int32, type : String, target : Int32)
    DATABASE.exec("delete from notifications where account_id = ? and type = ? and target = ?", account_id, type, target)
  end

  def send_notification(account_id : Int32, type : String, target : Int32?, details : NotificationDetails? = nil)
    DATABASE.exec("insert into notifications (id, account_id, type, target, details) values (?, ?, ?, ?, ?)", IDs.get_next_id("notifications"), account_id, type, target, details.try &.to_json || "{}")
  end

  NOTIFICATION_STRINGS = {
    "authored_level_featured" => %(Your level <b>%{level_name}</b> has been featured!),
    "authored_level_rated" => %(Your level <b>%{level_name}</b> has been rated!),
    "like_milestone" => %(Your level <b>%{level_name}</b> has reached <b>%{amount}</b> likes!),
    "download_milestone" => %(Your level <b>%{level_name}</b> has reached <b>%{amount}</b> downloads!)
  }

  def format_notification(type : String, target : Int32?, details : NotificationDetails? = nil, html_safe : Bool = false)
    details = details || {} of String => String | Int64 | Bool | Float64 | Nil
    string = NOTIFICATION_STRINGS[type]?

    if !string
      LOG.error { "No notification string found for #{type}" }
      # might aswell have a fallback
      return type
    end

    #case type
    #when "authored_level_featured", "authored_level_rated"
    #  details["action"] = (type == "authored_level_featured") ? "featured" : "rated"
    #end

    if html_safe
      string % details.transform_values { |v| HTML.escape v.to_s }
    else
      string % details
    end
  end
end
