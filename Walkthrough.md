# EKS Platform Core + Jenkins Pipeline - Step-by-Step Walkthrough

A phase-by-phase runbook for standing this project up from nothing, running it, and tearing it down. Each phase lists what to do. Design reasoning and trade-offs for *why* each choice was made live in `DESIGN_NOTES.md` - this doc is the "what to actually run" companion.

---

## Prerequisites

- AWS account with an IAM user that can create IAM policies/roles (you'll scope everything down from there)
- Terraform CLI, AWS CLI v2, `kubectl`, `helm`, `git` installed locally
- An SSH key pair you control (for the Jenkins EC2 instance)
- This repo cloned locally


---

## Phase 0 - AWS credentials

```bash
aws configure --profile <your-profile>
aws sts get-caller-identity --profile <your-profile>
export AWS_PROFILE=<your-profile>
```

Confirm the `Account` field matches the AWS account you intend to deploy into.


---

## Phase 1 - Bootstrap the Terraform state backend

The state bucket is created **outside** the main project, via its own local-backend Terraform config - this avoids the chicken-and-egg problem of needing a backend to store the state of the thing that creates the backend.

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

Expect: 4 resources created (S3 bucket, versioning, encryption, public access block).


**IAM checkpoint:** your deployer identity needs an S3-scoped policy (bucket create/read/write, plus the various `Get`* reads Terraform performs on refresh) before this will succeed. Scope `Resource` to the specific bucket ARN, not `*`.

---

## Phase 2 - VPC & Networking

```bash
cd ../environments/dev
terraform init
terraform plan
terraform apply
```

Expect: VPC, 2 public + 2 private subnets across 2 AZs, 1 Internet Gateway, 2 NAT Gateways (one per AZ), correctly paired per-AZ route tables, EKS subnet discovery tags.

**IAM checkpoint:** add the EC2/VPC networking permission statement before this stage - expect `AccessDenied` on `ec2:CreateVpc` etc. otherwise, and add actions as errors name them.


---

## Phase 3 - IAM Roles + EKS Cluster

Same `terraform apply` in `environments/dev` (all modules are wired into one root config; re-running `apply` picks up whatever's new in the plan).

Expect: cluster + node-group IAM roles, OIDC provider, EKS cluster, managed node group, deployer access entry.

**IAM checkpoint:** add IAM role management actions (`CreateRole`, `AttachRolePolicy`, scoped `PassRole` for the two specific roles, `iam:CreateServiceLinkedRole` on a fresh account) and EKS cluster/nodegroup actions as errors name them.

**Common snag:** if this is a genuinely fresh AWS account, expect one `AccessDenied` on `iam:CreateServiceLinkedRole` - first-ever EKS use in an account needs to bootstrap a service-linked role.

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
kubectl get nodes
```


---

## Phase 4 - Helm provider + kube-prometheus-stack

Same `terraform apply`. The Helm provider authenticates against the now-existing cluster via its endpoint, CA cert, and a short-lived `aws_eks_cluster_auth` token.


```bash
kubectl get pods -n monitoring
```

---

## Phase 5 - EBS CSI driver + StorageClass

Same `terraform apply`. This phase adds an IRSA-based IAM role (OIDC-federated trust policy, scoped to the `ebs-csi-controller-sa` service account), the `aws-ebs-csi-driver` EKS addon, and a `gp3` StorageClass.

```bash
kubectl get storageclass
kubectl get pvc -n monitoring
```

Expect both Grafana's and Prometheus's PVCs showing `Bound`.

---

## Phase 6 - Jenkins EC2 infrastructure

Same `terraform apply`. Requires `terraform.tfvars` values for `jenkins_ssh_public_key` and `admin_cidr` (your IP, `/32`).

```bash
terraform output jenkins_public_ip
```

Give the instance 2–3 minutes to run its boot script, then verify:

```bash
ssh -i <your-key> ubuntu@<jenkins_public_ip>
systemctl status jenkins
which terraform kubectl helm aws
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open `http://<jenkins_public_ip>:8080`, unlock with that password, install suggested plugins.


---

## Phase 7 - Jenkins credentials + Multibranch Pipeline job

1. **Plugins**: Manage Jenkins → Plugins → install Pipeline, Git, GitHub, GitHub API, GitHub Branch Source. Restart.
2. **Credential 1** (PR comments): Manage Jenkins → Credentials → Add → Kind: *Secret text* → paste your GitHub PAT → ID: `github-pat`.
3. **Credential 2** (Git checkout): Add → Kind: *Username with password* → username = your GitHub username, password = same PAT → ID: `github-pat-git-auth`.
4. **Credential 3** (tfvars): Add → Kind: *Secret file* → upload your local `terraform.tfvars` → ID: `tf-tfvars`.
5. **Job**: New Item → Multibranch Pipeline → Branch Sources → GitHub → your repo URL → select `github-pat-git-auth` → Save.


---

## Phase 8 - Run the pipeline

Push a commit (or open a PR) against the repo. Jenkins auto-discovers it via the Multibranch job and runs the `Jenkinsfile`: **Lint → Plan → Post Plan to PR → Manual Approval → Apply → Rollout verification**.

Click **Apply** at the Manual Approval prompt when ready.


---

## Phase 9 - Verify the running platform

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open `http://localhost:3000`, log in with `admin` / (`kubectl get secret --namespace monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode`).

---

## Phase 10 - Teardown

```bash
cd environments/dev
terraform destroy
cd ../../bootstrap
terraform destroy   # only if you're fully done - this deletes state history
```

Confirm in the AWS Console that the VPC, EKS cluster, EC2 instance, and NAT Gateways are gone (these are the cost-bearing resources - don't leave them running unintentionally).