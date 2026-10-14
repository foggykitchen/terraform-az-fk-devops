module "devops" {
  source = "../.."

  project_name = var.project_name
  service_connection = {
    name              = "fk-azure-oidc"
    subscription_id   = var.subscription_id
    subscription_name = var.subscription_name
  }

  github_service_connections = {
    hello_world = { name = "fk-github-hello-world" }
  }
}
