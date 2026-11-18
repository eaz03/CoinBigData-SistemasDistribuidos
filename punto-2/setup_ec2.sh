#!/bin/bash
# User data de la EC2 fuente (punto 2). AWS lo ejecuta como root solo en el primer arranque.
# Instala el cliente MariaDB y descarga del repositorio publico:
#   /data/bullion            archivos que se ingestan a S3 (punto 3)
#   /home/ec2-user/rds_seed  CSV y SQL que solo sirven para poblar RDS
set -euo pipefail

BASE=https://raw.githubusercontent.com/eaz03/CoinBigData-SistemasDistribuidos/main

dnf install -y mariadb105
mkdir -p /data/bullion /home/ec2-user/rds_seed

curl -fsSL -o /data/bullion/bullion-american-eagle-gold.csv "$BASE/punto-1/bullion-american-eagle-gold.csv"
curl -fsSL -o /data/bullion/bullion-american-buffalo.csv    "$BASE/punto-1/bullion-american-buffalo.csv"
curl -fsSL -o /home/ec2-user/rds_seed/producto_oro.csv      "$BASE/punto-1/producto_oro.csv"
curl -fsSL -o /home/ec2-user/rds_seed/evento_mercado.csv    "$BASE/punto-1/evento_mercado.csv"
curl -fsSL -o /home/ec2-user/rds_seed/catalogo_oro.sql      "$BASE/punto-2/rds/catalogo_oro.sql"

chown -R ec2-user:ec2-user /data /home/ec2-user/rds_seed
