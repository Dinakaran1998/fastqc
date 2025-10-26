

# 🧬 FastQC AWS Batch Pipeline

A **Nextflow-based FastQC pipeline** that runs on **AWS Batch** using custom Docker and S3 integration.  
Designed for simple testing and scalable production use with both **EC2** and **Fargate** compute environments.

---

## 📖 About

This repository provides a complete setup to run [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) quality control analysis on FASTQ files using **Nextflow** and **AWS Batch**.

It includes:

- A **Nextflow workflow** for FastQC  
- A **Docker container** for FastQC  
- **AWS Batch** configuration for compute environments and job queues  
- Step-by-step setup and deployment instructions  

---

## ⚙️ Prerequisites

Before running, ensure you have the following installed and configured:

| Tool | Description |
|------|--------------|
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | Manage AWS resources |
| [Docker](https://docs.docker.com/get-docker/) | Build and push your container image |
| [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html) | Run the pipeline |
| AWS Account | With permissions for S3, Batch, ECR, IAM, and VPC setup |

---

## 3. Create AWS Infrastructure (“VPC and more”)

When you select **“VPC and more”** in AWS Batch setup, AWS automatically creates:

✅ 1 VPC  
✅ 4 Subnets (2 public, 2 private across 2 AZs)  
✅ Route tables  
✅ Internet Gateway  
✅ NAT Gateway (optional)  
✅ Security Groups  

**Recommendation:**
- **Testing/learning:** Use **public subnets**
- **Production:** Use **private subnets + NAT Gateway**

---

## 4. Create AWS Batch Compute Environment

### Example (Fargate)
```bash
aws batch create-compute-environment \
  --compute-environment-name fastqc-fargate-env \
  --type MANAGED \
  --state ENABLED \
  --compute-resources "type=FARGATE,maxvCpus=64,subnets=subnet-057cd1067dbcac544,securityGroupIds=sg-070e160e270ed56fb"

---

## 5. Create an IAM Role for Batch

1. Go to **IAM → Roles → Create role**
2. Choose **Trusted entity: AWS service**
3. Choose **Use case: EC2**
4. Attach these policies:

   * `AmazonEC2ContainerServiceforEC2Role`
   * `AmazonEC2ContainerRegistryReadOnly`
   * `AmazonSSMManagedInstanceCore`
   * *(Optional)* `AmazonS3FullAccess`
5. Create the role and note its ARN.

---

## 6. Build and Push Docker Image

### Build

```bash
sudo docker build -t fastqc .
```

### Create ECR Repository

```bash
aws ecr create-repository --repository-name fastqc --region us-east-1
```

### Login to ECR

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin 539323004046.dkr.ecr.us-east-1.amazonaws.com
```

### Tag and Push

```bash
docker tag fastqc:latest 539323004046.dkr.ecr.us-east-1.amazonaws.com/fastqc:latest
docker push 539323004046.dkr.ecr.us-east-1.amazonaws.com/fastqc:latest
```

---

## 7. Running the Pipeline

### Option 1: Local Execution

```bash
nextflow run main.nf -profile local
```

### Option 2: AWS Batch Execution

```bash
nextflow run main.nf -profile awsbatch -resume
```

Results will be automatically uploaded to:

```
s3://aws-batch-input-bioinformatics/fastqc-results/
```

---

## 8. Best Practices

| Environment | Subnet Type | Internet Access | Notes          |
| ----------- | ----------- | --------------- | -------------- |
| Development | Public      | Direct via IGW  | Simplest setup |
| Production  | Private     | Via NAT Gateway | More secure    |

---

## 9. Scaling and Performance

* Use **multiple subnets across AZs** for high availability
* Increase `maxvCpus` in the compute environment to allow scaling
* Monitor jobs in **AWS Batch Console → Jobs**

---

## 10. Cleanup

To remove all AWS resources created for this demo:

```bash
aws batch delete-compute-environment --compute-environment fastqc-fargate-env
aws ecr delete-repository --repository-name fastqc --force
```

---
