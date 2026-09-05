# beam-testbed

A Phoenix 1.8 LiveView app on ECS Fargate at https://beam.kswiger.dev, deployed
entirely through the shared tooling in
[aws-reusable-workflows](https://github.com/kyleswiger/aws-reusable-workflows)
and [aws-deployment-tooling](https://github.com/kyleswiger/aws-deployment-tooling).
It is the reference consumer for the Elixir/BEAM path.

```
PR ──ci (elixir-ci.yml)──▶ main ──oci-build-push──▶ ECR beam-testbed@sha256:…
                                        │
                                  ecs-deploy (environment: production)
                                        │
                     ECS Fargate (ARM, Spot, public subnet) ◀── ALB + ACM ◀── beam.kswiger.dev
```

## Run locally

```bash
mix setup
mix phx.server          # http://localhost:4000
```

No Elixir installed? The versions in `.tool-versions` match the
`hexpm/elixir` image tag used by the Dockerfile:

```bash
docker run --rm -it -v "$PWD:/app" -w /app -p 4000:4000 \
  hexpm/elixir:1.19.2-erlang-28.1.1-debian-trixie-20260610-slim \
  bash -c 'mix local.hex --force && mix deps.get && mix phx.server'
```

## First deploy (once)

1. Secret, outside Terraform:
   ```bash
   aws ssm put-parameter --name /beam-testbed/secret_key_base --type SecureString \
     --value "$(openssl rand -base64 64)"
   ```
2. Infrastructure (ECR repo, roles, ALB, cert, service):
   ```bash
   cd terraform && terraform init && terraform apply
   ```
   The service starts with no image in the repo and stays at 0 running tasks
   (the circuit breaker rolls the empty deployment back). That is expected.
3. GitHub: create the `production` environment, add secret
   `AWS_GITHUB_ACTIONS_ROLE_ARN` = `terraform output -raw ci_role_arn`, add
   `CLAUDE_CODE_OAUTH_TOKEN`, and apply `.github/rulesets/main.json` with
   aws-deployment-tooling's `scripts/apply-branch-ruleset.sh --ruleset`.
4. Run the **Deploy** workflow by hand (workflow_dispatch). It builds the
   arm64 image, pushes it, registers a task-definition revision, and rolls the
   service to it. From then on every merge to `main` deploys.

## Cost

ARM 0.25 vCPU / 0.5 GB Spot task ≈ $2, ALB ≈ $16 + LCU, three public IPv4
addresses ≈ $11, logs and ECR pennies: **≈ $30/mo**. `capacity_provider =
"FARGATE"` adds ≈ $5. The ALB and IPv4 are the floor for a stable HTTPS
hostname with WebSockets; a Lambda Function URL would be $0 but cannot carry
LiveView's socket.
