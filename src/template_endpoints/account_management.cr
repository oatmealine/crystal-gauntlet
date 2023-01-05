require "uri"
require "compress/gzip"

include CrystalGauntlet

CrystalGauntlet.template_endpoints["/#{config_get("general.append_path").as(String | Nil) || ""}accounts/accountManagement.php"] = ->(context : HTTP::Server::Context) {
  context.response.headers.add("Location", "/accounts/")
  context.response.status = HTTP::Status::MOVED_PERMANENTLY
}

CrystalGauntlet.template_endpoints["/accounts"] = ->(context : HTTP::Server::Context) {
  context.response.content_type = "text/html"
  ECR.embed("./public/template/account_management.ecr", context.response)
}
