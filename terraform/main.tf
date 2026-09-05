# beam-testbed: one Phoenix LiveView container on ECS Fargate
# -------------------------------------------------------------
# Terraform owns the shape (cluster, service, ALB, TLS, roles); the Deploy
# workflow owns the running image (ECR push + new task-definition revision).
# Default VPC, public subnets, public IP: no NAT gateway, no VPC endpoints.

# Module refs: bump both `?ref=` to the aws-deployment-tooling release tag that
# contains ecs-fargate-service once PR #8 is released (Dependabot tracks it).

# 1. The service. Spot because this is a test stack; flip to FARGATE for
#    anything that must not be interrupted.
module "app" {
  source = "github.com/kyleswiger/aws-deployment-tooling//terraform-modules/ecs-fargate-service?ref=0b3288767d4fc51f309a707f7947dd62a21814f6"

  name_prefix       = var.name_prefix
  container_name    = "app"
  container_port    = 4000
  cpu               = 256
  memory            = 512
  architecture      = "ARM64"
  capacity_provider = var.capacity_provider
  desired_count     = 1

  custom_domain  = var.custom_domain
  hosted_zone_id = var.hosted_zone_id

  environment = {
    PHX_HOST   = var.custom_domain
    PORT       = "4000"
    PHX_SERVER = "true"
  }

  # Created out-of-band, never in state:
  #   aws ssm put-parameter --name /beam-testbed/secret_key_base --type SecureString --value "$(openssl rand -base64 64)"
  secrets = {
    SECRET_KEY_BASE = "arn:aws:ssm:us-east-1:${data.aws_caller_identity.current.account_id}:parameter/${var.name_prefix}/secret_key_base"
  }
}

# 2. Keyless CI role. The account already has the GitHub OIDC provider.
#    Permissions are exactly what oci-build-push + ecs-deploy + terraform plan need.
module "ci_role" {
  source = "github.com/kyleswiger/aws-deployment-tooling//terraform-modules/github-oidc-role?ref=0b3288767d4fc51f309a707f7947dd62a21814f6"

  name_prefix          = var.name_prefix
  github_repo          = var.github_repo
  create_oidc_provider = false

  subject_claims = [
    "repo:${var.github_repo}:ref:refs/heads/main",
    "repo:${var.github_repo}:pull_request",
    "repo:${var.github_repo}:environment:production",
  ]

  policy_statements = concat(module.app.ci_policy_statements, [
    {
      sid       = "TerraformPlanState"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::kyleswiger-tfstate-495407107865", "arn:aws:s3:::kyleswiger-tfstate-495407107865/${var.name_prefix}/*"]
    },
    {
      sid       = "TerraformPlanRead"
      effect    = "Allow"
      actions   = ["ecs:Describe*", "ecs:List*", "ec2:Describe*", "elasticloadbalancing:Describe*", "iam:Get*", "iam:List*", "logs:Describe*", "logs:ListTagsForResource", "acm:Describe*", "acm:List*", "route53:Get*", "route53:List*", "ecr:Describe*", "ecr:List*", "ecr:GetLifecyclePolicy", "ecr:GetRepositoryPolicy"]
      resources = ["*"]
    },
  ])
}

data "aws_caller_identity" "current" {}
