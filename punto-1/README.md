# Punto 1: Caso de estudio. Demanda de monedas de oro bullion vs. precio del oro

## 1. Objetivo

Crear un pipeline de datos que combine los datos históricos de ventas mensuales de monedas de oro bullion de la Casa de la Moneda de los Estados Unidos (United States Mint) entre 1986 y 2026; las fechas de recesiones económicas del NBER (National Bureau of Economic Research, institución privada de investigación económica que mantiene la cronología oficial de los ciclos económicos de EE. UU.), junto con otros choques financieros documentados; y el precio histórico del oro publicado por el Banco Mundial. Con estos datos se responden preguntas de negocio sobre la relación entre la compra de monedas de oro, las crisis económicas y el precio del oro.

## 2. Contexto de negocio

Las monedas de tipo bullion son productos de inversión que dependen del oro que contienen y no de su rareza. La Casa de la Moneda de EE. UU., oficina del Departamento del Tesoro, no las vende directamente al público, sino a una red de distribuidores mayoristas llamados Authorized Purchasers, que luego las revenden. Al público solo le venden directamente los productos numismáticos (de colección), como las versiones "Proof" (United States Mint, s. f.-c). Por eso, el volumen mensual de ventas bullion es un indicador directo de la demanda de oro físico por parte de inversionistas.

Entender cómo reacciona esta demanda ante el precio del oro y ante las crisis es útil para la Casa de la Moneda (planear producción e inventario), para los distribuidores (gestionar inventario) y para los inversionistas (identificar cuándo aumenta la demanda de oro físico). En este caso, permite también conectar distintas fuentes de datos en un solo lugar para resolver preguntas de negocio.

## 3. Preguntas de negocio

1. ¿Cómo cambian las ventas de monedas de oro durante una crisis? 
2. ¿Cómo ha cambiado el precio del oro durante periodos de problemas economicos?
3. ¿Cuál es el mes del año en el que más monedas de oro se venden, y es consistente en todos los años?
4. Si el precio del oro sube, ¿aumenta la compra de monedas de menor fracción (½, ¼ y 1/10 de onza)?
5. ¿Cuáles fueron los 5 meses con mayor valor en dólares de monedas vendidas (onzas vendidas × precio del oro de ese mes), y qué estaba haciendo el precio del oro en esos meses?
6. ¿Crece la participación de la moneda de 24 quilates (American Buffalo) en las onzas vendidas frente a la de 22 quilates (American Eagle)? 

Las preguntas se irán refinando a medida que avance el proyecto.

## 4. Fuentes de datos

- **Ventas mensuales de monedas de oro bullion (archivos en EC2).** La Casa de la Moneda de EE. UU. publica las ventas mensuales de cada una de sus monedas bullion y permite republicar estos datos citándola como fuente (United States Mint, 2026). En este caso se usan dos productos:
  - *American Eagle Gold*: oro de 22 quilates, en cuatro tamaños (1, ½, ¼ y 1/10 de onza troy de oro puro), con ventas desde octubre de 1986 (United States Mint, s. f.-b).
  - *American Buffalo Gold*: oro de 24 quilates (.9999), solo en 1 onza troy, con ventas desde junio de 2006 (United States Mint, s. f.-a).
- **Precio histórico del oro (URL).** Precio promedio mensual del oro en dólares por onza troy desde 1960, tomado del archivo *Pink Sheet* del Banco Mundial (World Bank, 2026), publicado bajo licencia CC BY 4.0.
- **Tablas de referencia (base de datos RDS MariaDB).**
  - `evento_mercado`: recesiones de EE. UU. según el NBER y choques económicos (caídas bursátiles, crisis financieras, pandemia, quiebras bancarias), con las fechas y la fuente de cada evento.
  - `producto_oro`: catálogo de las 5 monedas, con su contenido de oro en onzas (para convertir unidades vendidas a onzas de oro), peso bruto, diámetro, valor nominal y quilates, según las especificaciones oficiales de la Casa de la Moneda.

| Dataset | Fuente simulada | Cobertura | Formato | Licencia |
|---|---|---|---|---|
| Ventas American Eagle Gold | EC2 | oct. 1986 – sep. 2026, mensual | CSV | Republicable citando a la US Mint |
| Ventas American Buffalo Gold | EC2 | jun. 2006 – sep. 2026, mensual | CSV | Republicable citando a la US Mint |
| Precio del oro | URL | ene. 1960 – presente, mensual | XLSX | CC BY 4.0 |
| `evento_mercado` | RDS | 10 eventos, 1987 – 2023 | CSV → tabla | Elaboración propia a partir de fuentes oficiales |
| `producto_oro` | RDS | 5 productos | CSV → tabla | Elaboración propia a partir de especificaciones de la US Mint |

## 5. Decisiones de diseño

- **EC2:** Los CSV de ventas mensuales se cargan sin modificar a una instancia EC2, porque se actualizan cada mes y están organizados para ser leídos fácilmente por personas (bloques lado a lado, filas en blanco, formatos numéricos mixtos), pero no para ser procesados algorítmicamente, por lo que requieren procesamiento. Desde EC2 se ingieren al datalake (S3, zona *raw*) y su limpieza se realiza en el punto 4 con AWS Glue.
- **URL:** Los datos del Banco Mundial tienen acceso fácil mediante un enlace público directo, sin llave de API, y además cambian en el tiempo (se actualizan mensualmente), lo cual es ideal para la ingesta automática por URL.
- **RDS:** Las tablas fueron creadas específicamente limpias a partir de fuentes oficiales y listas para ingresar a un sistema SQL, como ocurre con los datos maestros de una organización (catálogo de productos y calendario de eventos). No son extensas, pero son fácilmente expandibles. No incluyen correcciones de los CSV de ventas: toda la limpieza de los datos crudos ocurre dentro del pipeline.
- **Alcance:** Solo se incluyen monedas de oro, para limitar la complejidad; las monedas de plata y platino se podrían agregar después con el mismo pipeline.
- **Fuente descartada:** Se evaluó la API de Numista como fuente de datos numismáticos, pero su licencia solo permite almacenar sus datos en proyectos privados de un individuo para sus propias actividades numismáticas, que no se pongan a disposición del público ni de miembros de una organización (Numista, s. f.), condición que no cumple un proyecto académico.

## 6. Archivos de esta carpeta y cómo reproducirlos

| Archivo | Descripción | Cómo se obtuvo |
|---|---|---|
| `bullion-american-eagle-gold.csv` | Ventas mensuales de American Eagle Gold, 4 tamaños | Descargado el 17 de noviembre de 2026 de la sección *Bullion* de https://www.usmint.gov/data#bull |
| `bullion-american-buffalo.csv` | Ventas mensuales de American Buffalo Gold, 1 oz | Descargado el 17 de noviembre de 2026 de la sección *Bullion* de https://www.usmint.gov/data#bull |
| `producto_oro.csv` | Catálogo de productos (tabla de RDS) | Elaborado por los autores con las especificaciones oficiales de la US Mint; la columna `fuente_url` indica la página de cada moneda |
| `evento_mercado.csv` | Eventos económicos (tabla de RDS) | Elaborado por los autores; las columnas `fuente_nombre` y `fuente_url` citan la fuente de las fechas de cada evento |
| `numista-data.py` | Prueba exploratoria de la API de Numista | Fuente descartada (ver sección 5); requiere la variable de entorno `NUMISTA_API_KEY` |

El precio del oro no se guarda en esta carpeta: se descarga automáticamente desde su URL en el punto 3.

Para reproducir:

1. Descargar los CSV de ventas bullion de *American Eagle Gold* y *American Buffalo Gold* desde https://www.usmint.gov/data#bull, o usar los de esta carpeta.
2. Verificar que el enlace del precio del oro funcione: https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/related/CMO-Historical-Data-Monthly.xlsx. El Banco Mundial cambia esta ruta cada año; si falla, tomar el enlace *Monthly prices* de https://www.worldbank.org/commodities.
3. Los archivos `producto_oro.csv` y `evento_mercado.csv` se cargan a RDS MariaDB en el punto 2.

## 7. Referencias

Anthropic. (2026). *Claude* (versión Opus 5.5) [Modelo de lenguaje de gran tamaño]. https://claude.ai

Bernhardt, D., & Eckblad, M. (2013). *Stock market crash of 1987*. Federal Reserve History. https://www.federalreservehistory.org/essays/stock-market-crash-of-1987

Contino, M. D. (2023). *Financial institution insolvency and the federal response to the regional bank failures of 2023* (Informe CRS R47658). Congressional Research Service. https://www.everycrsreport.com/reports/R47658.html

Federal Reserve History. (s. f.-a). *Asian financial crisis*. https://www.federalreservehistory.org/essays/asian-financial-crisis

Federal Reserve History. (s. f.-b). *Near failure of Long-Term Capital Management*. https://www.federalreservehistory.org/essays/ltcm_near_failure

Federal Reserve History. (s. f.-c). *The Great Recession and its aftermath*. https://www.federalreservehistory.org/essays/great-recession-and-its-aftermath

National Bureau of Economic Research. (s. f.). *US business cycle expansions and contractions* [Conjunto de datos]. Recuperado el 17 de noviembre de 2026, de https://www.nber.org/research/data/us-business-cycle-expansions-and-contractions

Numista. (s. f.). *Numista API terms of use and license agreement*. Recuperado el 17 de noviembre de 2026, de https://en.numista.com/api/license.php

Pinto, B., & Ulatov, S. (2010). *Financial globalization and the Russian crisis of 1998* (Policy Research Working Paper No. 5312). Banco Mundial. https://openknowledge.worldbank.org/bitstreams/06417085-7d0c-5505-b106-2be08e529965/download

United States Mint. (s. f.-a). *American Buffalo gold bullion coin*. Recuperado el 17 de noviembre de 2026, de https://usmint.gov/?p=4908

United States Mint. (s. f.-b). *American Eagle gold bullion coins*. Recuperado el 17 de noviembre de 2026, de https://usmint.gov/?p=4845

United States Mint. (s. f.-c). *Production and sales figures*. Recuperado el 17 de noviembre de 2026, de https://www.usmint.gov/about/production-sales-figures

United States Mint. (2026). *Bullion sales figures: American Eagle Gold y American Buffalo Gold* [Conjunto de datos]. Recuperado el 17 de noviembre de 2026, de https://www.usmint.gov/data#bull

World Bank. (2026). *World Bank commodity price data (The Pink Sheet): Monthly prices* [Conjunto de datos]. https://thedocs.worldbank.org/en/doc/74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/related/CMO-Historical-Data-Monthly.xlsx

World Health Organization. (2020, 11 de marzo). *WHO Director-General's opening remarks at the media briefing on COVID-19 - 11 March 2020*. https://www.who.int/news-room/speeches/item/who-director-general-s-opening-remarks-at-the-media-briefing-on-covid-19---11-march-2020

### Atribución de datos

- Datos de ventas bullion: United States Mint, citado como fuente según sus condiciones de republicación.
- Precios del oro: Banco Mundial, *Commodity Price Data (The Pink Sheet)*, bajo licencia CC BY 4.0.

### Declaración de uso de inteligencia artificial

Se utilizó Claude (Anthropic, versión Opus 5.5) como asistente para: (a) buscar y comparar fuentes de datos numismáticos y revisar sus licencias de uso (Numista, US Mint, Banco Mundial, Banco de la República); (b) recopilar, a partir de fuentes oficiales, las fechas de los eventos de `evento_mercado.csv` y las especificaciones de `producto_oro.csv`; y (c) revisar la redacción de este documento. La definición del caso, las preguntas de negocio y las decisiones de diseño fueron tomadas por los autores, quienes contrastaron las cifras y referencias con las fuentes originales enlazadas.
