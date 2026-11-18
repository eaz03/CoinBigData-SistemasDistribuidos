#!/bin/bash
# Punto 2, red: 2 grupos de seguridad y el endpoint de S3 en la VPC por defecto.
# Uso: bash punto-2/cli/01_red.sh   (terminal del Learner Lab o equipo con credenciales del lab)
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

VPC_ID=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text)

# EC2 fuente: sin reglas de entrada (se administra con Session Manager); salida libre por defecto
EC2_SG=$(aws ec2 create-security-group --vpc-id "$VPC_ID" \
  --group-name ec2-fuente-sg --description "EC2 fuente de archivos, sin entrada" \
  --query GroupId --output text)

# RDS: entrada solo desde la EC2 (3306) y desde el mismo grupo (requisito de Glue)
RDS_SG=$(aws ec2 create-security-group --vpc-id "$VPC_ID" \
  --group-name rds-mariadb-sg --description "RDS MariaDB, entrada desde EC2 y Glue" \
  --query GroupId --output text)

aws ec2 authorize-security-group-ingress --group-id "$RDS_SG" \
  --protocol tcp --port 3306 --source-group "$EC2_SG"
aws ec2 authorize-security-group-ingress --group-id "$RDS_SG" \
  --protocol tcp --port 0-65535 --source-group "$RDS_SG"

# Endpoint Gateway: Glue llega a S3 desde la VPC sin salir a internet
RT_ID=$(aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=true \
  --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-vpc-endpoint --vpc-id "$VPC_ID" --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3 --route-table-ids "$RT_ID" \
  --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=s3-gateway}]' \
  --query 'VpcEndpoint.VpcEndpointId' --output text

echo "VPC=$VPC_ID  EC2_SG=$EC2_SG  RDS_SG=$RDS_SG  RT=$RT_ID"
