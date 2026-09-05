output "url" {
  value = module.app.url
}

output "alb_dns_name" {
  value = module.app.alb_dns_name
}

output "ecr_repository_url" {
  value = module.app.ecr_repository_url
}

output "ci_role_arn" {
  description = "Set as the AWS_GITHUB_ACTIONS_ROLE_ARN secret on the production environment"
  value       = module.ci_role.role_arn
}

output "cluster_name" {
  value = module.app.cluster_name
}

output "service_name" {
  value = module.app.service_name
}
