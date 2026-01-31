# Ciroos Demo Infrastructure

This Terraform project creates the AWS infrastructure for the Ciroos AI SRE Teammate demo environment.

## 🏗️ What This Creates

| Resource | Description | Estimated Cost |
|----------|-------------|----------------|
| VPC | Private network with public/private subnets | ~$1/day (NAT) |
| EKS Cluster | Managed Kubernetes (2 t3.medium nodes) | ~$4/day |
| RDS PostgreSQL | Database (db.t3.micro) | ~$0.50/day |
| ElastiCache Redis | Cache (cache.t3.micro) | ~$0.50/day |
| S3 Bucket | Log storage | ~$0.01/day |
| **TOTAL** | | **~$6-7/day** |

## 📋 Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** installed and configured
   ```bash
   aws configure
   # Enter your Access Key, Secret Key, region (us-east-1)
   ```
3. **Terraform** v1.0+ installed
   ```bash
   # Mac
   brew install terraform
   
   # Windows (with Chocolatey)
   choco install terraform
   
   # Linux
   # See: https://developer.hashicorp.com/terraform/downloads
   ```
4. **kubectl** installed
   ```bash
   # Mac
   brew install kubectl
   
   # Others: https://kubernetes.io/docs/tasks/tools/
   ```

## 🚀 Quick Start

### Step 1: Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values (especially db_password!)
nano terraform.tfvars
```

### Step 2: Initialize Terraform

```bash
terraform init
```

This downloads the required providers and modules.

### Step 3: Preview Changes

```bash
terraform plan
```

Review what will be created. You should see ~25-30 resources.

### Step 4: Create Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This takes **15-20 minutes**.

### Step 5: Configure kubectl

After apply completes, run the command shown in the output:

```bash
aws eks update-kubeconfig --region us-east-1 --name globalretail-demo
```

### Step 6: Verify Connection

```bash
kubectl get nodes
```

You should see 2 nodes in "Ready" state.

## 🧹 Cleanup (IMPORTANT!)

To avoid ongoing charges, destroy the infrastructure when done:

```bash
terraform destroy
```

Type `yes` when prompted. This takes ~10 minutes.

## 📁 Project Structure

```
ciroos-demo-infra/
├── main.tf              # Main resources (VPC, EKS, RDS, etc.)
├── variables.tf         # Input variable definitions
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── versions.tf          # Required versions
├── terraform.tfvars     # Your variable values (DON'T COMMIT!)
├── .gitignore           # Files to ignore in Git
└── README.md            # This file
```

## 🔧 Customization

### Change Region
Edit `terraform.tfvars`:
```hcl
aws_region = "us-west-2"
availability_zones = ["us-west-2a", "us-west-2b"]
```

### Change Node Size
For more capacity:
```hcl
node_instance_type = "t3.large"
node_desired_count = 3
```

### Enable Multi-AZ RDS
For production-like setup (costs more):
```hcl
# Add to main.tf in the RDS module:
multi_az = true
```

## 🐛 Troubleshooting

### "Error: Kubernetes cluster unreachable"
Your kubectl isn't configured. Run:
```bash
aws eks update-kubeconfig --region us-east-1 --name globalretail-demo
```

### "Error creating EKS: Cluster already exists"
A cluster with this name exists. Either:
- Change `cluster_name` in terraform.tfvars
- Delete the existing cluster in AWS Console

### Terraform is slow
First-time EKS creation takes 15-20 minutes. This is normal.

### State file issues
If you get state errors:
```bash
# Remove local state (CAREFUL - only if nothing deployed)
rm -rf .terraform terraform.tfstate*
terraform init
```

## 📚 Next Steps

After infrastructure is ready:

1. **Deploy microservices** (next Terraform/Helm project)
2. **Configure AppDynamics agents**
3. **Set up Splunk forwarder**
4. **Connect to Ciroos**

## 💡 Cost Saving Tips

1. **Destroy when not using**: `terraform destroy`
2. **Use smaller instances** for quick tests: `t3.small`
3. **Skip Multi-AZ** for demos: Use single NAT gateway (default)
4. **Set up billing alerts** in AWS Console

---

Created for the Ciroos.ai Practice Assignment
