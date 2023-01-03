require "uri"

include CrystalGauntlet

CrystalGauntlet.endpoints["/getGJDailyLevel.php"] = ->(context : HTTP::Server::Context): String {
  params = URI::Params.parse(context.request.body.not_nil!.gets_to_end)
  LOG.debug { params.inspect }

  weekly = params["weekly"] == "1"

  level_id = nil
  expires = nil

  level_id, expires, idx = Dailies.fetch_current_level(weekly)

  if !level_id || !expires || !idx
    "-1"
  else
    if weekly
      idx += Dailies::WEEKLY_OFFSET
    end

    [idx, expires].join("|")
  end
}
