include CrystalGauntlet

module CrystalGauntlet::IDs
  extend self

  def get_next_id(key : String) : Int32
    begin
      id = DATABASE.query_one("select id from next_id where name = ?", key, as: {Int32})
    rescue
      next_id = 1
      DATABASE.exec("insert into next_id (name, id) values (?, ?)", key, next_id)
      next_id
    else
      next_id = id + 1
      DATABASE.exec("update next_id set id = ? where name = ?", next_id, key)
      return next_id
    end
  end
end
