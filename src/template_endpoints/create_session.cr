require "uri"
require "compress/gzip"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[{
  name: "create_session",
  path: "/tools/create_session",
  methods: ["get", "post"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  disabled = !config_get("sessions.allow").as(Bool | Nil)
  result = nil
  body = context.request.body
  if body && !disabled
    begin
      params = URI::Params.parse(body.gets_to_end)
      result = Accounts.new_session(context.request, params["username"], params["password"])

    rescue error
      LOG.error {"whar.... #{error}"}
    end
  end

  context.response.content_type = "text/html"
  ECR.embed("./public/template/create_session.ecr", context.response)
}
