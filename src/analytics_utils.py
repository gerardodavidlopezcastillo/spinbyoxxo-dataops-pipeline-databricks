"""
Analytics Utilities - Funciones de apoyo para limpieza y transformacion de datos
"""

import logging
from pyspark.sql import DataFrame
from pyspark.sql import functions as F
from pyspark.sql.types import (
    DateType,
    TimestampType,
    StringType,
    IntegerType,
    DoubleType,
)
from src.constants import (
    DATE_FORMAT_SAP,
    DEFAULT_DATE_DUMMY,
    DEFAULT_TIMESTAMP_DUMMY,
    DEFAULT_STRING_VALUE,
    DEFAULT_NUMERIC_VALUE,
)

# Obtenemos la configuracipon de Logging escrita en main
logger = logging.getLogger(__name__)


class AnalyticsUtils:

    @staticmethod
    def cleaning_df_spark(df: DataFrame) -> DataFrame:
        """
        Limpieza generica de un DataFrame PySpark:
            - Columnas de fecha: rellenar con fecha dummy si es nula
            - Columnas timestamp: rellenar con timestamp dummy
            - Columnas numericas: rellenar con 0
            - Columnas string (no fecha): rellenar con 'PD' (por definir)
        """
        df_clean = df

        for field in df_clean.schema.fields:
            col_name = field.name
            dtype = field.dataType

            # Fechas
            if isinstance(dtype, DateType):
                df_clean = df_clean.withColumn(
                    col_name,
                    F.when(
                        F.col(col_name).isNull(),
                        F.lit(DEFAULT_DATE_DUMMY).cast(
                            DateType()
                        ),  # 1900-01-01: Fecha dummy (Default)
                    ).otherwise(F.col(col_name)),
                )

            # Timestamps
            elif isinstance(dtype, TimestampType):
                df_clean = df_clean.withColumn(
                    col_name,
                    F.when(
                        F.col(col_name).isNull(),
                        F.lit(DEFAULT_TIMESTAMP_DUMMY).cast(
                            TimestampType()
                        ),  # 1900-01-01 00:00:00: Fecha dummy (Default)
                    ).otherwise(F.col(col_name)),
                )

            # Strings/Integer de fecha tipo "yyyyMMdd"
            elif (
                isinstance(dtype, (StringType, IntegerType))
                and "fecha" in col_name.lower()
            ):
                df_clean = df_clean.withColumn(
                    col_name,
                    F.when(
                        F.col(col_name).isNull() | (F.col(col_name) == ""),
                        F.lit(DEFAULT_DATE_DUMMY),  # 1900-01-01: Fecha dummy (Default)
                    ).otherwise(
                        F.to_date(F.col(col_name).cast("string"), DATE_FORMAT_SAP)
                    ),
                )

            # Strings
            elif isinstance(dtype, StringType):
                df_clean = df_clean.withColumn(
                    col_name,
                    F.when(
                        F.col(col_name).isNull() | (F.col(col_name) == ""),
                        F.lit(DEFAULT_STRING_VALUE),  # PD: Por Definir (Default)
                    ).otherwise(F.col(col_name)),
                )

            # Numeros
            elif isinstance(dtype, (IntegerType, DoubleType)):
                df_clean = df_clean.withColumn(
                    col_name,
                    F.when(
                        F.col(col_name).isNull(), F.lit(DEFAULT_NUMERIC_VALUE)
                    ).otherwise(
                        F.col(col_name)
                    ),  # 0: Valor default
                )

        logger.info(
            f"Limpieza aplicada a {len(df_clean.columns)} columnas y {df_clean.count()} filas"
        )

        return df_clean
