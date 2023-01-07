require "uri"

include CrystalGauntlet

comments_per_page = 10

CrystalGauntlet.endpoints["/getGJAccountComments20.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

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
        2 => Base64.urlsafe_encode(comment),
        3 => account_id,
        4 => likes,
        5 => 0, # dislikes; unused
        6 => id,
        7 => likes <= config_get("comments.spam_thres", -3_i64),
        9 => Time.parse(created_at, Format::TIME_FORMAT, Time::Location::UTC),
      })
    end
  end

  search_meta = "#{amount}:#{comment_offset}:#{comments_per_page}"

  [users_str.join("|"), search_meta].join("#")
}
