#!/bin/bash
# Punto 2, EC2 fuente de archivos. Requiere 01_red.sh.
# Uso: bash punto-2/cli/02_ec2.sh
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
cd "$(dirname "$0")/../.."   # raiz del repo, para encontrar setup_ec2.sh

VPC_ID=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
EC2_SG=$(aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=ec2-fuente-sg \
  --query 'SecurityGroups[0].GroupId' --output text)
# Subred por defecto de us-east-1a, para no caer en una zona sin t3.micro
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values="$VPC_ID" Name=availability-zone,Values=us-east-1a Name=default-for-az,Values=true \
  --query 'Subnets[0].SubnetId' --output text)

# Sin par de llaves: no hay SSH, se entra con Session Manager (LabInstanceProfile lo permite)
aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.micro \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$EC2_SG" \
  --associate-public-ip-address \
  --iam-instance-profile Name=LabInstanceProfile \
  --user-data file://punto-2/setup_ec2.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ec2-fuente-archivos}]' \
  --query 'Instances[0].InstanceId' --output text
