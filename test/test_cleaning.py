"""
Test unitario para validar la logica de limpieza de datos en Spark.

Este test NO busca probar Spark como framework (eso ya lo hace Apache),
sino verificar que nuestra logica de negocio funciona correctamente
sobre un DataFrame de Spark en un entorno controlado.
"""

import pytest
from pyspark.sql import SparkSession
from src.analytics_utils import AnalyticsUtils
from src.constants import DEFAULT_STRING_VALUE


# Reutilizable, necesario para que se cree una sola vez para toda la ejecucion de pytest
@pytest.fixture(scope="session")
def spark():
    """
    Crea una sesion de Spark local para los tests.

    - scope="session" indica que esta sesion se crea UNA sola vez para toda la ejecucion de los tests (mejor performance).
    - master="local[1]" ejecuta Spark en modo local con 1 hilo.
    - appName informativo.

    Esta sesion se inyecta automaticamente en los tests que
    reciben el parametro `spark`.
    """

    return (
        SparkSession.builder.master("local[1]")
        .appName("TestAnalyticsUtils")
        .getOrCreate()
    )


def test_limpieza_strings(spark):
    """
    Valida que la funcion de limpieza de strings:
        - Reemplace valores NULL
        - Reemplace strings vacios

    usando el valor por defecto definido en las constantes ("PD").
    """

    # Preparacion
    # Creamos un DataFrame de prueba con datos "sucios"
    # - None simula un NULL
    # - "" simula un string vacio
    data = [("A", None), ("B", "")]
    df = spark.createDataFrame(data, ["id", "texto"])

    # Ejecucion
    # Ejecutamos la logica real de negocio que queremos validar creada anteriormente en AnalyticsUtils
    df_clean = AnalyticsUtils.cleaning_df_spark(df)

    # Validacion - ASSERT (la clave de todo)
    # Convertimos el DataFrame a una lista de filas para poder inspeccionarlo
    rows = df_clean.collect()

    # Verificamos que los valores NULL y vacios fueron reemplazados correctamente por "PD"
    assert rows[0]["texto"] == DEFAULT_STRING_VALUE
    assert rows[1]["texto"] == DEFAULT_STRING_VALUE
