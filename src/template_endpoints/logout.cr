require "uri"
require "http-session"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/accounts/logout"] = ->(context : HTTP::Server::Context) {
  if context.request.method != "POST"
    context.response.respond_with_status 405
    return
  end

  CrystalGauntlet.sessions.delete(context)

  context.response.headers.add("Location", "/")
  context.response.status = HTTP::Status::SEE_OTHER
  return
}
