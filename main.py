# Parche para Databricks: El kernel interno de IPython de Databricks omite __package__, lo que rompe la librería ipynb.
try:
    import IPython
    ip = IPython.get_ipython()
    if ip is not None and '__package__' not in ip.user_ns:
        ip.user_ns['__package__'] = None
except Exception:
    pass

import ipynb.fs.full
import importlib
import os
import sys
import argparse
import logging
from omegaconf import OmegaConf
from pyspark.sql import SparkSession

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_spark_session():
    return SparkSession.builder \
        .appName("ECart_Lakehouse_ETL") \
        .config("spark.jars.packages", "io.delta:delta-spark_2.12:3.1.0") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .getOrCreate()

def run_pipeline(is_onpremise=False):
    spark = create_spark_session()
    
    # 1. Resolver rutas absolutas para Databricks
    # En Databricks (spark_python_task), el código corre en un kernel de IPython donde __file__ no existe.
    # Afortunadamente, Databricks Asset Bundles automáticamente ajusta el 'cwd' (current working directory)
    # a la raíz del proyecto subido.
    base_dir = os.getcwd()
    sys.path.append(base_dir) # Para que importlib encuentre las carpetas silver y gold
    
    logger.info("Cargando config.yaml...")
    config_path = os.path.join(base_dir, "conf/config.yaml")
    config = OmegaConf.load(config_path)

    # 2. Simular el esquema de Databricks creando la base de datos local
    spark.sql("CREATE DATABASE IF NOT EXISTS silver")
    spark.sql("CREATE DATABASE IF NOT EXISTS gold")

    # 3. Iterar sobre las capas dinámicamente (silver, gold)
    for layer in ["silver", "gold"]:
        if layer in config.tables:
            logger.info(f"========== PROCESANDO CAPA {layer.upper()} ==========")
            
            for table_key, table_config in config.tables[layer].items():
                if table_config.active == 1:
                    logger.info(f"--- Iniciando tabla: {table_key} ---")
                    
                    module_path = table_config.module_path
                    module_name, class_name = module_path.rsplit(".", 1)
                    notebook_module_path = f"ipynb.fs.full.{module_name}"
                    module = importlib.import_module(notebook_module_path)
                    TableClass = getattr(module, class_name)
                    
                    table_config_dict = OmegaConf.to_container(table_config, resolve=True)
                    
                    if is_onpremise:
                        if "source_path" in table_config_dict:
                            table_config_dict["source_path"] = table_config_dict["source_path"].replace("s3://spinbyoxxo-datalake-bronze", "bronze")
                        
                        if "catalog" in table_config_dict:
                            table_config_dict["catalog"] = "spark_catalog"
                            
                        if "source_table" in table_config_dict:
                            table_config_dict["source_table"] = table_config_dict["source_table"].replace("spinbyoxxo.", "")
                            
                        if "source_tables" in table_config_dict:
                            for key in table_config_dict["source_tables"]:
                                table_config_dict["source_tables"][key] = table_config_dict["source_tables"][key].replace("spinbyoxxo.", "")
                    
                    job = TableClass(spark, table_config_dict)
                    job.execute()
                else:
                    logger.info(f"Tabla {table_key} inactiva. Saltando...")

    spark.stop()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ejecutar ETL Lakehouse")
    parser.add_argument("--onpremise", action="store_true", help="Ejecutar localmente sobre escribiendo rutas de S3")
    args = parser.parse_args()
    
    run_pipeline(is_onpremise=args.onpremise)
