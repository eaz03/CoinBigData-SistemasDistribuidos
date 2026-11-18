#!/bin/bash
# Punto 2, RDS MariaDB privada. Requiere 01_red.sh.
# Uso: bash punto-2/cli/03_rds.sh
# Pide la clave maestra (8 a 41 caracteres, sin / " @ ni espacios); no queda guardada en archivos.
set -euo pipefail
export AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""

read -rsp "Clave maestra de RDS: " DB_PASSWORD; echo

VPC_ID=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
RDS_SG=$(aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=rds-mariadb-sg \
  --query 'SecurityGroups[0].GroupId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'Subnets[].SubnetId' --output text)
# Ultima version menor de MariaDB 10.11 (LTS, soporte en RDS hasta 2028)
ENGINE_VERSION=$(aws rds describe-db-engine-versions --engine mariadb \
  --query "DBEngineVersions[?starts_with(EngineVersion, '10.11')].EngineVersion | [-1]" --output text)

# shellcheck disable=SC2086  # SUBNETS se separa en palabras a proposito
aws rds create-db-subnet-group --db-subnet-group-name rds-mariadb-subnets \
  --db-subnet-group-description "Subredes de la VPC por defecto" \
  --subnet-ids $SUBNETS \
  --query 'DBSubnetGroup.DBSubnetGroupName' --output text

# Restricciones del Learner Lab: db.t3.micro, Single-AZ, <=100 GB, sin monitoreo mejorado
aws rds create-db-instance \
  --db-instance-identifier fuente-mariadb \
  --engine mariadb --engine-version "$ENGINE_VERSION" \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 --storage-type gp2 \
  --db-name catalogo_oro \
  --master-username admin --master-user-password "$DB_PASSWORD" \
  --db-subnet-group-name rds-mariadb-subnets \
  --vpc-security-group-ids "$RDS_SG" \
  --no-publicly-accessible --no-multi-az \
  --backup-retention-period 0 --monitoring-interval 0 \
  --no-enable-performance-insights --no-deletion-protection \
  --query 'DBInstance.DBInstanceStatus' --output text

echo "Esperando a que la base quede disponible (5 a 15 min)..."
aws rds wait db-instance-available --db-instance-identifier fuente-mariadb
echo "Endpoint:"
aws rds describe-db-instances --db-instance-identifier fuente-mariadb \
  --query 'DBInstances[0].Endpoint.Address' --output text
