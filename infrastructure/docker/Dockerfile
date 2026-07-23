# Imagen Base: Python 3.10 ligero, basado en Bullseye
FROM python:3.10-slim-bullseye

# Metadatos del proyecto
LABEL maintainer="Gerardo David Lopez Castillo"
LABEL project="globaltask-data-pipeline"
LABEL description="GlobalTask Data Pipeline - Arquitectura Hibrida"

# Instalar Java por uso de Spark
# Usamos OpenJDK 11 que es el estandar actual para Spark 3.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless curl procps zip unzip git bash && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurar Variables de Entorno
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3
ENV ENV=cloud
ENV PYTHONUNBUFFERED=1
ENV HADOOP_CONF_DIR=/opt/spark/jars
ENV SPARK_CLASSPATH=/opt/spark/jars/hadoop-aws-3.3.4.jar:/opt/spark/jars/aws-java-sdk-bundle-1.12.540.jar

# para llegar a S3
RUN mkdir -p /opt/spark/jars
RUN curl -L -o /opt/spark/jars/hadoop-aws-3.3.4.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
RUN curl -L -o /opt/spark/jars/aws-java-sdk-bundle-1.12.540.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.540/aws-java-sdk-bundle-1.12.540.jar

# Crear directorio de trabajo
WORKDIR /app

# Gestion de Dependencias
# Copiamos primero solo el requirements.txt para aprovechar la cache de Docker
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el Codigo Fuete
COPY . .

# Usuario no-root
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Comando con parametros necesarios o extras (Ejecuta en modo OnPremise si no se especifica otro)
# CMD ["python", "main.py", "pipeline.env=cloud"]
ENTRYPOINT ["python", "main.py"]
CMD ["pipeline.env=cloud"]