# Nodejs_project

## Overview
This repository provisions and deploys a sample Node.js application onto an Amazon EKS cluster. Terraform is used to stand up every AWS dependency (VPC, subnets, IAM, EKS, ECR, and the AWS Load Balancer Controller). Kubernetes manifests deploy the application, service, and ingress. GitHub Actions automate both the infrastructure lifecycle and the application delivery pipeline.

## Repository Layout
- `infra/` – Terraform configuration that creates network primitives, an ECR repository, the EKS control plane + managed node group, and installs the AWS Load Balancer Controller through Helm/IRSA.
- `k8s/` – Namespace, Deployment, Service, and Ingress manifests for the Node.js workload; the service is exposed via an ALB managed by the controller.
- `node-app/` – Source for the Node.js application that is containerized and pushed to ECR.
- `.github/workflows/` – Deployment workflow for the Node app (build → push → kube apply), Terraform plan/apply workflows, and a nightly destroy workflow that tears down infra at 12 AM IST.

## Terraform Infrastructure (`infra/`)
1. **Providers & Data Sources** – The AWS provider talks to the target region. After the cluster is created, data sources fetch the cluster endpoint/CA/token for the Kubernetes and Helm providers so Terraform can install cluster add‑ons.
2. **Networking** – `aws_vpc`, public subnets, route table, and associations give EKS workers public internet access and tag subnets for load balancers.
3. **ECR** – `aws_ecr_repository.practice_node_app` stores images built by CI, with lifecycle rules ignoring mutable attributes.
4. **IAM** – Cluster and node-group roles attach the standard AWS managed policies. An IAM OIDC provider plus a custom role/policy powers IRSA for the AWS Load Balancer Controller.
5. **EKS + Node Group** – `aws_eks_cluster.practice` and `aws_eks_node_group.default` form the control plane and worker nodes, sized through variables.
6. **AWS Load Balancer Controller** – Terraform creates the service account, attaches the IAM policy from `iam-policy-alb.json`, then installs the Helm chart to automatically manage ALBs for ingress objects.

### Working with Terraform
```bash
cd infra
terraform init
terraform plan          # review changes
terraform apply         # create/update resources
terraform destroy       # tear everything down
```
The nightly destroy GitHub Action can be disabled if persistent environments are needed. After any Terraform change, re-run `terraform plan` to update `.terraform.lock.hcl` so the provider versions stay in sync.

## Kubernetes Manifests (`k8s/`)
- `namespace.yaml` – Creates the `practice-app` namespace.
- `deployment.yaml` – Deploys the Node.js container pulled from ECR.
- `service.yaml` – Exposes pods on port 80 using the cluster IP; the AWS Load Balancer Controller registers targets from this service.
- `ingress.yaml` – Requests an internet-facing ALB (`alb.ingress.kubernetes.io/scheme`) with IP targets and HTTP listener on port 80. Once the controller reconciles it, the `kubectl get ingress -n practice-app` output shows the ALB DNS name.

Apply/update the manifests:
```bash
kubectl apply -f k8s/namespace.yaml \
  -f k8s/deployment.yaml \
  -f k8s/service.yaml \
  -f k8s/ingress.yaml
```
Verify ALB provisioning with `kubectl get ingress practice-node-app -n practice-app -o wide` and curl the returned DNS name.

## GitHub Actions
1. **deploy-node-app.yml** – Builds the Docker image, logs into ECR, pushes the new tag, updates the Kubernetes deployment, and rolls out changes.
2. **Terraform Plan/Apply workflows** – Run Terraform in GitHub-hosted runners. Separate jobs perform plan (for review) and apply (after approval). AWS credentials are passed through encrypted secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.).
3. **terraform-destroy.yml** – Scheduled workflow that runs `terraform destroy` nightly (cron for 12 AM IST) to keep AWS usage low.

## End-to-End Flow
1. Commit application or infra changes.
2. Terraform plan/apply workflows provision/modify the AWS stack.
3. The deploy workflow builds the container, pushes to ECR, and updates the Kubernetes deployment inside EKS.
4. The AWS Load Balancer Controller detects the ingress and creates an ALB that fronts the service.
5. Access the app through the ALB DNS name or via Route 53 if you attach a custom domain.

## Troubleshooting Tips
- If Terraform complains about lock-file mismatches, rerun `terraform init -upgrade`.
- When the ingress lacks an address, inspect controller logs: `kubectl -n kube-system logs deploy/aws-load-balancer-controller`.
- Use `aws eks update-kubeconfig --name practice-node-app --region <region>` after cluster creation to interact with kubectl locally.

With these pieces working together, you can reproducibly create, deploy, and tear down the entire environment from source control.
