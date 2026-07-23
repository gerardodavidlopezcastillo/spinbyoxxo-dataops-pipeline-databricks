"""ETL para procesar datos de entrega de Global Mobility mediante PySpark."""

import logging
from datetime import datetime
from omegaconf import DictConfig
from .analytics_utils import AnalyticsUtils
from pyspark.sql.functions import current_timestamp
from pyspark.sql import SparkSession, DataFrame, functions as F
from src.constants import (
    DATE_FORMAT_SAP,
    SPARK_APP_NAME,
    SPARK_UI_PORT,
    # etc. demas variables en un ambiente real corporativo, en este caso se dejan unicamente estas
)

# Obtenemos la configuracipon de Logging escrita en main
logger = logging.getLogger(__name__)


class ETLEngineer:
    """Motor ETL responsable de leer (extraccion), transformar y escribir (carga) datos de entregas.

    Atributos:
        conf (DictConfig): Configuracion del pipeline y de las reglas de negocio.
        spark (SparkSession): Sesion activa de Spark.
        df (DataFrame | None): DataFrame de trabajo para el pipeline.
    """

    def __init__(self, conf: DictConfig) -> None:
        self.conf = conf

        builder = (  # Inicia SparkSession, session lo encapsula todo.
            SparkSession.builder.appName(SPARK_APP_NAME)
            .config(  # Controla el paralelismo al hacer Joins o GroupBy.
                "spark.sql.shuffle.partitions", str(self.conf.spark.shuffle_partitions)
            )
            .config(
                "spark.ui.port", SPARK_UI_PORT
            )  # Puerto para ver la Spark UI la web donde monitoreas el DAG
        )

        #  Onpremise
        if self.conf.pipeline.env == "onpremise":
            builder = builder.master(
                "local[*]"
            )  # El asterisco indica a Spark que use todos los hilos (núcleos) lógicos disponibles en tu CPU para el procesamiento en paralelo

        # Cloud
        if self.conf.pipeline.env == "cloud":
            builder = (
                builder
                # Habilitar S3A
                .config(  # Define la clase concreta que implementa el sistema de archivos S3A
                    "spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem"
                ).config(  #
                    "spark.hadoop.fs.s3a.aws.credentials.provider",
                    "com.amazonaws.auth.DefaultAWSCredentialsProviderChain",
                )
                # Aqui usamos jars locales configurados en Dockerfile en lugar de descargarlos con packages. Ya que estaba dando problemas en la ejucion de docker local
                .config(  # Especifica manualmente la ruta de los archivos JAR necesarios para conectar Hadoop con AWS.
                    "spark.jars",
                    "/opt/spark/jars/hadoop-aws-3.3.4.jar,/opt/spark/jars/aws-java-sdk-bundle-1.12.540.jar",
                )
            )

        self.spark = (
            builder.getOrCreate()
        )  # Si ya existe una sesión activa en este proceso, la devuelve; si no, instancia una nueva. Es el punto de entrada para programar con Spark.

        # Configuración de escritura particionada
        if self.conf.pipeline.write_mode.lower() == "overwrite":
            self.spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

        self.df: DataFrame | None = None

    def read_data(self) -> DataFrame:
        """Lee datos de la fuente configurada (local o S3)."""

        input_path = self.conf.pipeline.input_path
        logger.info(f"Leyendo datos de: {input_path}")

        try:
            # Iniciso 1 - Leer csv
            # Se parametriza lectura de csv desde OmegaConf
            self.df_read = self.spark.read.csv(
                input_path, header=True, inferSchema=True
            )

            return self.df_read

        except Exception as e:
            logger.error(f"Error leyendo el archivo: {e}")
            raise

    def transform_data(self) -> DataFrame:
        """Aplica transformaciones utilizando reglas de negocio de la configuracion."""

        self.df_transorm = self.df_read

        if self.df_transorm is None:
            raise ValueError("Dataframe vacio.")

        logger.info("Aplicando transformaciones y reglas de negocio")

        # Se agregam columnas clave para logs/auditoria
        input_path = self.conf.pipeline.input_path
        file_name = input_path.split("/")[-1].rsplit(".", 1)[0]
        file_extension = input_path.split(".")[-1].lower()
        self.df_transorm = (
            self.df_transorm.withColumn("desc_fuente", F.lit(file_extension))
            .withColumn("desc_nombre_archivo", F.lit(file_name))
            .withColumn("dtm_fecha_carga", current_timestamp())
        )

        # Inciso 2 - Filtro por rango de fechas desde OmegaConfig
        # Conversion de Fechas
        self.df_transorm = self.df_transorm.withColumn(
            "fecha_proceso",
            F.to_date(F.col("fecha_proceso").cast("string"), DATE_FORMAT_SAP),
        )

        start_date = datetime.strptime(
            str(self.conf.pipeline.start_date), "%Y%m%d"
        ).date()
        end_date = datetime.strptime(str(self.conf.pipeline.end_date), "%Y%m%d").date()
        logger.info(f"Rango de fechas a procesar: {start_date} a {end_date}")

        self.df_transorm = self.df_transorm.filter(
            (F.col("fecha_proceso") >= start_date)
            & (F.col("fecha_proceso") <= end_date)
        )

        # Inciso 5 - Filtro por Pais desde OmegaConfig
        # Dinamico segun configuracion e instrucciones de prueba
        countries = self.conf.pipeline.country
        self.df_transorm = self.df_transorm.filter(
            F.col("pais") == self.conf.pipeline.country
        )

        fechas = [
            row["fecha_proceso"].strftime("%Y%m%d")
            for row in self.df_transorm.select("fecha_proceso").distinct().collect()
        ]
        logger.info(
            f"Paises a procesar: {countries} con las fechas encontradas en el input para el pais: {fechas}"
        )

        # Inciciso 6 - Normalizacion de unidades desde OmegaConfig
        # Estandarizacion de Unidades desde Business Rules
        units_dict = dict(self.conf.business_rules.units_conversion)
        unit_map = F.create_map([F.lit(x) for x in sum(units_dict.items(), ())])

        self.df_transorm = self.df_transorm.withColumn(
            "num_unidades", unit_map[F.col("unidad")]
        ).withColumn(
            "cantidad_unidades_totales",
            F.col("cantidad") * F.col("num_unidades"),
        )

        # Inciso 7 - Clasificacion de Tipo de Entrega
        # Logica de Tipos de Entrega, (ZPRE/ZVE1 rutina, Z04/Z05 bonificacion)
        rutina_types = list(self.conf.business_rules.delivery_types.rutina)
        bonif_types = list(self.conf.business_rules.delivery_types.bonificacion)

        valid_types = rutina_types + bonif_types

        # Filtrar tipos validos
        self.df_transorm = self.df_transorm.filter(
            F.col("tipo_entrega").isin(*valid_types)
        )

        # Crear columnas necesarias como booleanas
        self.df_transorm = self.df_transorm.withColumn(
            "es_entrega_rutina",
            F.when(F.col("tipo_entrega").isin(*rutina_types), 1).otherwise(0),
        ).withColumn(
            "es_entrega_bonificacion",
            F.when(F.col("tipo_entrega").isin(*bonif_types), 1).otherwise(0),
        )

        # Inciso 9 - Limpieza de datos / manejo de anomalias
        # Limpieza de datos a travez de un archivo analytics_utils.py
        self.df_transorm = AnalyticsUtils.cleaning_df_spark(self.df_transorm)
        num_rows_before = self.df_transorm.count()
        self.df_transorm = self.df_transorm.dropDuplicates()
        num_rows_after = self.df_transorm.count()
        num_duplicates_removed = num_rows_before - num_rows_after
        logger.info(
            f"Se quitaron {num_duplicates_removed} filas duplicadas, de un total de {num_rows_before} filas"
        )

        return self.df_transorm

    def write_data(self) -> DataFrame:
        """Renombrar columnas y escribir según el entorno"""

        self.df_write = self.df_transorm

        # Inciso 8 - Se estandarizan nombres de columnas de forma clara y consistente usando "desc", "vlr", "id", "num"
        # Seleccion final de columnas
        df_write = self.df_write.select(
            F.date_format(F.col("fecha_proceso"), DATE_FORMAT_SAP).alias(
                "fecha_particion"
            ),
            F.col("desc_fuente"),
            F.col("desc_nombre_archivo"),
            F.col("dtm_fecha_carga"),
            F.col("pais").alias("desc_pais"),
            F.col("transporte").alias("id_transporte"),
            F.col("ruta").alias("id_ruta"),
            F.col("material").alias("cod_sku_material"),
            F.col("unidad").alias("desc_unidad"),
            F.col("num_unidades"),
            F.col("cantidad"),
            F.col("cantidad_unidades_totales"),
            F.col("precio").alias("vlr_precio"),
            F.col("tipo_entrega").alias("desc_tipo_entrega"),
            F.col("es_entrega_rutina"),
            F.col("es_entrega_bonificacion"),
        )

        # Validacion de datos vacios antes de escribir
        if df_write.rdd.isEmpty():
            logger.warning(
                "El filtro aplicado no genero resultados. No se escribiran datos."
            )

        # Configuracion de salida
        output_path = self.conf.pipeline.output_path
        write_format = self.conf.pipeline.format  # 'csv' o 'parquet'

        logger.info(f"Escribiendo datos en: {output_path}")
        logger.info(
            f"Modo: {self.conf.pipeline.write_mode.upper()} dinamico por particion (fecha_particion)"
        )
        logger.info(f"Formato: {write_format.upper()}")

        # Iniciso 3 - Salidas particionadas por fecha_proceso -> fecha_particion
        # Escritura por particion
        df_write.write.partitionBy("fecha_particion").mode(
            self.conf.pipeline.write_mode
        ).parquet(output_path)

        return self.df_write

    def run(self) -> None:
        """Ejecuta el proceso ETL completo: lectura, transformacion y escritura."""

        try:
            self.read_data()
            self.transform_data()
            self.write_data()
            logger.info("Pipeline completado exitosamente.")

        except Exception as e:
            logger.error(f"Fallo critico en el pipeline: {e}")
            self.spark.stop()
            raise
