-- Punto 2: crea y llena las 2 tablas curadas de RDS. Se puede ejecutar varias veces.
-- Uso, en la EC2 por Session Manager (pide la clave):
--   mysql -h <endpoint-rds> -u admin -p --local-infile=1 --default-character-set=utf8mb4 < /home/ec2-user/rds_seed/catalogo_oro.sql

CREATE DATABASE IF NOT EXISTS catalogo_oro;
ALTER DATABASE catalogo_oro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE catalogo_oro;

CREATE TABLE IF NOT EXISTS producto_oro (
  id_producto        VARCHAR(10)   NOT NULL PRIMARY KEY,
  linea_producto     VARCHAR(40)   NOT NULL,
  contenido_oro_oz   DECIMAL(5,4)  NOT NULL,
  peso_bruto_g       DECIMAL(6,3)  NOT NULL,
  diametro_mm        DECIMAL(5,2)  NOT NULL,
  valor_nominal_usd  SMALLINT      NOT NULL,
  finura             DECIMAL(5,4)  NOT NULL,
  quilates           TINYINT       NOT NULL,
  anio_lanzamiento   SMALLINT      NOT NULL,
  fuente_url         VARCHAR(255)  NOT NULL
) DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS evento_mercado (
  id_evento      INT           NOT NULL PRIMARY KEY,
  nombre_evento  VARCHAR(120)  NOT NULL,
  categoria      VARCHAR(20)   NOT NULL,
  mes_inicio     DATE          NOT NULL,
  mes_fin        DATE          NOT NULL,
  fuente_nombre  VARCHAR(255)  NOT NULL,
  fuente_url     VARCHAR(500)  NOT NULL,
  CHECK (categoria IN ('choque', 'recesion')),
  CHECK (mes_fin >= mes_inicio)
) DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- Vaciar antes de cargar para que la recarga no duplique ni falle por llave repetida
TRUNCATE TABLE producto_oro;
TRUNCATE TABLE evento_mercado;

LOAD DATA LOCAL INFILE '/home/ec2-user/rds_seed/producto_oro.csv'
INTO TABLE producto_oro
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '/home/ec2-user/rds_seed/evento_mercado.csv'
INTO TABLE evento_mercado
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Evidencia: se esperan 5 y 10 filas
SELECT 'producto_oro' AS tabla, COUNT(*) AS filas FROM producto_oro
UNION ALL
SELECT 'evento_mercado', COUNT(*) FROM evento_mercado;
