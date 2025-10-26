---

# 🧬 FastQC AWS Batch Pipeline

A **Nextflow-based FastQC pipeline** that runs on **AWS Batch** using custom Docker and S3 integration.
Designed for simple testing and scalable production use with **EC2** compute environments.

---

## 📖 About

This repository provides a complete setup to run [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) quality control analysis on FASTQ files using **Nextflow** and **AWS Batch**.

**FastQC** is a widely used bioinformatics tool for **quality control of high-throughput sequencing data**. It generates reports for each FASTQ file, highlighting issues such as:

* Poor sequence quality
* Adapter contamination
* Overrepresented sequences
* GC content anomalies

This pipeline allows you to run FastQC in a **scalable, cloud-based environment** using AWS Batch and EC2 instances. It includes:

* A **Nextflow workflow** for FastQC
* A **Docker container** for FastQC
* **AWS Batch** configuration for compute environments and job queues
* Step-by-step setup and deployment instructions

---

## ⚙️ Prerequisites

Before running, ensure you have the following installed and configured:

| Tool                                                                                        | Description                                             |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | Manage AWS resources                                    |
| [Docker](https://www.docker.com/get-docker/)                                                | Build and push your container image                     |
| [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html)                             | Run the pipeline                                        |
| AWS Account                                                                                 | With permissions for S3, Batch, ECR, IAM, and VPC setup |

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

* **Testing/learning:** Use **public subnets**
* **Production:** Use **private subnets + NAT Gateway**

---

## 4. Create AWS Batch Compute Environment (EC2)

### Option 1: AWS CLI

```bash
aws batch create-compute-environment \
  --compute-environment-name fastqc-ec2-env \
  --type MANAGED \
  --state ENABLED \
  --compute-resources "type=EC2,instanceRole=ecsInstanceRole,instanceTypes=m5.large,minvCpus=0,maxvCpus=16,desiredvCpus=2,subnets=subnet-xxxxx,securityGroupIds=sg-xxxxx,ec2KeyPair=<your-keypair>" \
  --service-role AWSBatchServiceRole
```

**Notes:**

* `instanceRole` should be the IAM role for EC2 instances (`ecsInstanceRole`)
* `instanceTypes` can be changed based on your compute requirements
* `subnets` should include at least one subnet from your VPC

---

### Option 2: AWS Console

1. Go to **AWS Batch → Compute Environments → Create**
2. Choose **Managed** and **EC2** type
3. Enter a **Name** (e.g., `fastqc-ec2-env`)
4. Choose **Service Role:** `AWSBatchServiceRole`
5. Choose **Instance Role:** `ecsInstanceRole`
6. Select **VPC and Subnets**
7. Set **Min/Max/Desired vCPUs**
8. Select **Instance types**
9. Click **Create**

---

## 5. Create AWS Batch Job Queue

### Option 1: AWS CLI

```bash
aws batch create-job-queue \
  --job-queue-name fastqc-queue \
  --state ENABLED \
  --priority 1 \
  --compute-environment-order "order=1,computeEnvironment=fastqc-ec2-env"
```

### Option 2: AWS Console

1. Go to **AWS Batch → Job Queues → Create**
2. Enter **Name** (e.g., `fastqc-queue`)
3. Set **Priority** (e.g., `1`)
4. Choose **Compute Environment Order** and select your EC2 environment
5. Click **Create**

---

## 6. Create an IAM Role for Batch

1. Go to **IAM → Roles → Create role**
2. Choose **Trusted entity: AWS service**
3. Choose **Use case: EC2**
4. Attach these policies:

   * `AmazonEC2ContainerServiceforEC2Role`
   * `AmazonEC2ContainerRegistryReadOnly`
   * `AmazonSSMManagedInstanceCore`
   * *(Optional)* `AmazonS3FullAccess`
5. Create the role and note its ARN

---

## 7. Build and Push Docker Image

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
  | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com
```

### Tag and Push

```bash
docker tag fastqc:latest <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/fastqc:latest
docker push <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/fastqc:latest
```

---

## 8. Running the Pipeline

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

## 9. Best Practices

| Environment | Subnet Type | Internet Access | Notes          |
| ----------- | ----------- | --------------- | -------------- |
| Development | Public      | Direct via IGW  | Simplest setup |
| Production  | Private     | Via NAT Gateway | More secure    |

---

## 10. Scaling and Performance

* Use **multiple subnets across AZs** for high availability
* Increase `maxvCpus` in the compute environment to allow scaling
* Monitor jobs in **AWS Batch Console → Jobs**

---

## 11. Cleanup

To remove all AWS resources created for this demo:

```bash
aws batch delete-compute-environment --compute-environment fastqc-ec2-env
aws batch delete-job-queue --job-queue fastqc-queue
aws ecr delete-repository --repository-name fastqc --force
```

---