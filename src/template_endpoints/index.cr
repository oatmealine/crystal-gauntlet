require "ecr"

include CrystalGauntlet

CrystalGauntlet.template_endpoints[""] = ->(context : HTTP::Server::Context): String {
  ECR.render("./public/template/index.ecr")
}
