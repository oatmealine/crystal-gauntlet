require "json"

include CrystalGauntlet

module CrystalGauntlet::Notifications
  extend self

  alias NotificationValue = Hash(String, String | Int64 | Bool | Float64 | Nil)

  def clear_previous_notifications(account_id : Int32, type : String, target : Int32)
    DATABASE.exec("delete from notifications where account_id = ? and type = ? and target = ?", account_id, type, target)
  end

  def send_notification(account_id : Int32, type : String, target : Int32?, details : NotificationValue? = nil)
    DATABASE.exec("insert into notifications (id, account_id, type, target, details) values (?, ?, ?, ?, ?)", IDs.get_next_id("notifications"), account_id, type, target, details.try &.to_json || "{}")
  end
end
