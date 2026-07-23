"""
Analytics Helpers - Funciones de apoyo para calculos analiticos y logica del negocio
"""

import logging

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

    def gobernanza_validar_nit_boolean(self, df, *cols):
        return df
