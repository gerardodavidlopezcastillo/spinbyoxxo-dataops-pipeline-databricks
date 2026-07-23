"""
Constantes globales del proyecto GlobalTask Data Pipeline.
Centraliza valores fijos/quemados (hardcoded) para evitar 'Magic Strings' (eliminar magic strings) y duplicacion de codigo en proyectos grandes corporativos
las variales hardcoded siempre van en mayuscula para distinguirlas
"""

# Formato de fechas/timestamps
DATE_FORMAT_SAP = "yyyyMMdd"

# Valores por defecto/dummy
DEFAULT_DATE_DUMMY = "1900-01-01"
DEFAULT_TIMESTAMP_DUMMY = "1900-01-01 00:00:00"
DEFAULT_STRING_VALUE = "PD"  # Por Definir
DEFAULT_NUMERIC_VALUE = 0

# Configuraciones spark
SPARK_APP_NAME = "GlobalMobilityETL"
SPARK_UI_PORT = "4050"

######### Se comenta ya que es una prueba tecnica, no un proyecto real corporativo, no sobre-ingenierizar la prueba
# # ETL / Nombres de columnas estandar
# COL_FECHA_PARTICION = "fecha_particion"
# COL_DESC_FUENTE = "desc_fuente"
# COL_DESC_NOMBRE_ARCHIVO = "desc_nombre_archivo"
# COL_DTM_FECHA_CARGA = "dtm_fecha_carga"
# COL_DESC_PAIS = "desc_pais"
# COL_ID_TRANSPORTE = "id_transporte"
# COL_ID_RUTA = "id_ruta"
# COL_COD_SKU_MATERIAL = "cod_sku_material"
# COL_DESC_UNIDAD = "desc_unidad"
# COL_NUM_UNIDADES = "num_unidades"
# COL_CANTIDAD = "cantidad"
# COL_CANTIDAD_UNIDADES_TOTALES = "cantidad_unidades_totales"
# COL_VLR_PRECIO = "vlr_precio"
# COL_DESC_TIPO_ENTREGA = "desc_tipo_entrega"
# COL_ES_ENTREGA_RUTINA = "es_entrega_rutina"
# COL_ES_ENTREGA_BONIFICACION = "es_entrega_bonificacion"

# Otros filtrod dummy etc
# (Se pueden agregar aqui constantes de negocio futuras)
