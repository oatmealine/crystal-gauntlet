require "uri"

include CrystalGauntlet

comments_per_page = 10

CrystalGauntlet.endpoints["/getGJAccountComments20.php"] = ->(body : String): String {
  params = URI::Params.parse(body)
  puts params.inspect

  account_id = params["accountID"].to_i

  comment_offset = (params["page"]? || "0").to_i * comments_per_page

  amount = DATABASE.scalar("select count(*) from account_comments where account_id = ?", account_id)

  users_str = [] of String

  DATABASE.query("select id, comment, created_at, likes from account_comments where account_id = ? order by created_at desc limit #{comments_per_page} offset #{comment_offset}", account_id) do |rs|
    rs.each do
      id = rs.read(Int32)
      comment = rs.read(String)
      created_at = rs.read(String)
      likes = rs.read(Int32)

      users_str << Format.fmt_comment({
        2 => Base64.encode(comment).strip("\n"),
        3 => account_id,
        4 => likes,
        5 => 0,
        7 => likes < -3, # todo: config?
        #9 => Format.fmt_timespan(Time.utc - Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC)),
        6 => id
      })
    end
  end

  search_meta = "#{amount}:#{comment_offset}:#{comments_per_page}"

  [users_str.join("|"), search_meta].join("#")
}
