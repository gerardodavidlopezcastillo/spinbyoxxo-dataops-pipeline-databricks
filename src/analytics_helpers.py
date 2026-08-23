"""
Analytics Helpers - Funciones de apoyo para calculos analiticos y logica del negocio
"""

import logging
from pyspark.sql import DataFrame
from pyspark.sql import functions as F

# Obtenemos la configuracipon de Logging escrita en main
logger = logging.getLogger(__name__)


class AnalyticsHelpers:

    def __init__(self, spark=None):
        self.logger = logging.getLogger(__name__)

    def calcular_growth(
        self, df, venta_col, ventasanteriores_col, nombre_columna_returno="vlr_growth"
    ):
        return df

    def calcular_cogs(
        self, df, venta_col, margen_bruto_col, nombre_columna_returno="vlr_cogs"
    ):
        return df


class AnalyticsGobernanzaHelpers:
    
    @staticmethod
    def gobernanza_validar_nit_boolean(df: DataFrame, *cols) -> DataFrame:
        return df

    @staticmethod
    def enmascarar_pii_sha256(df: DataFrame, columnas_pii: list) -> DataFrame:
        """
        Aplica un hash SHA-256 a columnas sensibles (ej. emails, teléfonos) 
        para cumplir con normativas de seguridad (GDPR/Data Privacy).
        """
        df_masked = df
        for col_name in columnas_pii:
            if col_name in df_masked.columns:
                df_masked = df_masked.withColumn(
                    f"{col_name}_hash", 
                    F.sha2(F.col(col_name).cast("string"), 256)
                ).drop(col_name) # Eliminamos la columna original cruda
                
        logger.info(f"Enmascaramiento PII aplicado a las columnas: {columnas_pii}")
        return df_masked