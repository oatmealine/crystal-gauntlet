include CrystalGauntlet

module CrystalGauntlet::IPs
  extend self

  # todo: this could be better
  def get_real_ip(req : HTTP::Request)
    if config_get("trust_proxy").as?(Bool) && req.headers.has_key?("X-Forwarded-For")
      req.headers.get("X-Forwarded-For").first.split(",").first.strip
    else
      req.remote_address.to_s.split(":").first
    end
  end
end
