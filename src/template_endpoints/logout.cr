require "uri"
require "http-session"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[{
  name: "logout",
  path: "/accounts/logout",
  methods: ["post"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  CrystalGauntlet.sessions.delete(context)

  context.response.headers.add("Location", "/")
  context.response.status = HTTP::Status::SEE_OTHER
  return
}
