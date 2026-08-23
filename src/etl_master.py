import logging

class LakehouseMaster:
    def __init__(self, spark, table_config):
        self.spark = spark
        self.logger = logging.getLogger(self.__class__.__name__)
        self.config = table_config
        
        # Parámetros generales
        self.source_type = table_config.get("source_type", "csv")
        self.target_catalog = table_config.get("catalog", "spark_catalog")
        self.target_schema = table_config["schema"]
        self.target_table = table_config["table_name"]
        self.write_mode = table_config.get("write_mode", "overwrite")
        self.partition_columns = table_config.get("partition_columns", [])

        # Parámetros de Gobierno de Datos
        self.owner = table_config.get("owner", "unassigned")

    def extract(self):
        self.logger.info(f"Extrayendo datos (Tipo: {self.source_type})")
        
        if self.source_type == "csv":
            return self.spark.read.format("csv").option("header", True).load(self.config["source_path"])
            
        elif self.source_type == "table":
            return self.spark.read.table(self.config["source_table"])
            
        elif self.source_type == "multiple_tables":
            # Retorna un diccionario de DataFrames para cruces (JOINs)
            dfs = {}
            for key, table_name in self.config["source_tables"].items():
                dfs[key] = self.spark.read.table(table_name)
            return dfs
            
        else:
            raise ValueError(f"Tipo de origen no soportado: {self.source_type}")

    def transform(self, df):
        raise NotImplementedError("Debe implementar el método transform")

    def load(self, df):
        full_table_name = f"{self.target_catalog}.{self.target_schema}.{self.target_table}"
        self.logger.info(f"Guardando en Delta Table: {full_table_name} | Data Owner: {self.owner}")
        
        # Preparamos el escritor
        writer = df.write.format("delta").mode(self.write_mode)
        
        # Si el YAML trae particiones, se las inyectamos dinámicamente
        if self.partition_columns:
            self.logger.info(f"Aplicando particiones por: {self.partition_columns}")
            writer = writer.partitionBy(*self.partition_columns)
            
        writer.saveAsTable(full_table_name)

        # En un entorno real de Databricks, aquí ejecutarías:
        # self.spark.sql(f"ALTER TABLE {full_table_name} SET TBLPROPERTIES ('owner' = '{self.owner}')")

    def execute(self):
        df_raw = self.extract()
        df_transformed = self.transform(df_raw)
        self.load(df_transformed)