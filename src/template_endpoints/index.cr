require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[""] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"
  ECR.embed("./public/template/index.ecr", context.response)
}
