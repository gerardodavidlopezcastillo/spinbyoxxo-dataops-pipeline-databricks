resource "aws_glue_catalog_database" "globaltask" { # crea la base de datos logica en el catalogo de glue para organizar las tablas
  name        = "globaltask"
  description = "Glue database for GlobalTask datasets"
}

resource "aws_glue_catalog_table" "st_global_test" {
  name          = "st_global_test"
  database_name = aws_glue_catalog_database.globaltask.name
  table_type    = "EXTERNAL_TABLE" # indica que los datos residen en s3 y glue solo guarda los metadatos

  parameters = {
    classification = "parquet" # ayuda a los crawlers y athena a identificar el formato del archivo
    EXTERNAL       = "TRUE" # marca explicita requerida para tablas que apuntan a s3
  }

  storage_descriptor {
    location      = "s3://${var.processed_bucket}/mobility/processed/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat" # clase de hadoop optimizada para leer archivos parquet
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat" # clase de hadoop para escribir en formato parquet

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe" # libreria serde para serializar y deserializar datos parquet eficientemente
    }

    columns {
      name = "desc_fuente"
      type = "string"
    }

    columns {
      name = "desc_nombre_archivo"
      type = "string"
    }

    columns {
      name = "dtm_fecha_carga"
      type = "timestamp"
    }

    columns {
      name = "desc_pais"
      type = "string"
    }

    columns {
      name = "id_transporte"
      type = "int"
    }

    columns {
      name = "id_ruta"
      type = "int"
    }

    columns {
      name = "cod_sku_material"
      type = "string"
    }

    columns {
      name = "desc_unidad"
      type = "string"
    }

    columns {
      name = "num_unidades"
      type = "int"
    }

    columns {
      name = "cantidad"
      type = "double"
    }

    columns {
      name = "cantidad_unidades_totales"
      type = "double"
    }

    columns {
      name = "vlr_precio"
      type = "double"
    }

    columns {
      name = "desc_tipo_entrega"
      type = "string"
    }

    columns {
      name = "es_entrega_rutina"
      type = "int"
    }

    columns {
      name = "es_entrega_bonificacion"
      type = "int"
    }
  }

  partition_keys {
    name = "fecha_particion"
    type = "bigint"
  }
}
