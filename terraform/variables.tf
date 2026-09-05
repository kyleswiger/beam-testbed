variable "name_prefix" {
  type    = string
  default = "beam-testbed"
}

variable "github_repo" {
  type    = string
  default = "kyleswiger/beam-testbed"
}

variable "custom_domain" {
  type    = string
  default = "beam.kswiger.dev"
}

variable "hosted_zone_id" {
  description = "kswiger.dev public zone"
  type        = string
  default     = "Z00418782SGUGERFA8BVX"
}

variable "capacity_provider" {
  description = "FARGATE_SPOT for the test stack; FARGATE for anything that must not be interrupted"
  type        = string
  default     = "FARGATE_SPOT"
}

variable "tooling_ref" {
  description = "aws-deployment-tooling git ref for the modules. Pin to a release tag once one exists that contains ecs-fargate-service."
  type        = string
  default     = "main"
}
