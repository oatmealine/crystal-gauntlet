module CrystalGauntlet::Reupload
  extend self

  REUPLOAD_ACC_USERNAME = "Reupload"

  @@reupload_acc_id = 0

  def init()
    begin
      @@reupload_acc_id = DATABASE.query_one("select id from accounts where username = ?", REUPLOAD_ACC_USERNAME, as: {Int32})
      LOG.debug { "reupload acc id #{@@reupload_acc_id}" }
    rescue
      next_id = IDs.get_next_id("accounts")
      DATABASE.exec("insert into accounts (id, username, password, gjp2, email, is_admin, messages_enabled, friend_requests_enabled, comments_enabled) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", next_id, REUPLOAD_ACC_USERNAME, "!", "!", "", 1, 0, 0, 0)
      DATABASE.exec("insert into users (id, udid, account_id, registered, username) values (?, ?, ?, ?, ?)", IDs.get_next_id("users"), nil, next_id, 1, REUPLOAD_ACC_USERNAME)
      LOG.debug { "created reupload acc id #{next_id}" }
      @@reupload_acc_id = next_id
    end
  end

  def reupload_acc_id()
    @@reupload_acc_id
  end
end
