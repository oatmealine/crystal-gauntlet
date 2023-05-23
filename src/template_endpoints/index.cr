require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[{
  name: "tools_redirect",
  path: "/tools",
  methods: ["get"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.headers.add("Location", "/")
  context.response.status = HTTP::Status::TEMPORARY_REDIRECT
}


CrystalGauntlet.template_endpoints[{
  name: "index",
  path: "/",
  methods: ["get"]
}] = ->(context : HTTP::Server::Context, params : Hash(String, String?)) {
  context.response.content_type = "text/html"
  ECR.embed("./public/template/index.ecr", context.response)
}
