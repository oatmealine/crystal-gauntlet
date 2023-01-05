require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/tools"] = ->(context : HTTP::Server::Context) {
  context.response.headers.add("Location", "/")
  context.response.status = HTTP::Status::TEMPORARY_REDIRECT
}

CrystalGauntlet.template_endpoints[""] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"
  ECR.embed("./public/template/index.ecr", context.response)
}
