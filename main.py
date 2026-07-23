import sys
import logging
from omegaconf import OmegaConf
from src.etl import ETLEngineer

# Configuración de Logging Global
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def load_config() -> OmegaConf:
    """
    Carga la configuración en cascada:
        1. Base (Reglas de Negocio)
        2. Entorno (OnPremise vs Cloud)
        3. CLI (Argumentos de terminal)
    """

    try:
        # Cargar parametros base indicados en prueba
        base_conf = OmegaConf.load("conf/base/parameters.yaml")

        # Detectar Entorno (Default: onpremise), se pede cambiar ejecutando: python main.py pipeline.env=cloud
        cli_conf = OmegaConf.from_cli()
        env = cli_conf.get("pipeline", {}).get("env", "onpremise")

        logger.info(f"Inicializando configuración para entorno: {env.upper()}")

        # Cargar Configuración de entorno OmegaConf
        env_config_path = f"conf/{env}/env.yaml"
        env_conf = OmegaConf.load(env_config_path)

        # Fusionar (CLI manda sobre Entorno, Entorno manda sobre Base)
        final_omegaconf = OmegaConf.merge(base_conf, env_conf, cli_conf)

        # Validación visual de rutas (para debug)
        logger.info(f"Input:  {final_omegaconf.pipeline.input_path}")
        logger.info(f"Output: {final_omegaconf.pipeline.output_path}")

        return final_omegaconf

    except FileNotFoundError as e:
        logger.error(f"Error de configuración: No se encontró el archivo {e.filename}")
        logger.error(
            f"Asegúrate de que existan: conf/base/parameters.yaml y conf/{env}/env.yaml"
        )
        sys.exit(1)

    except Exception as e:
        logger.error(f"Error inesperado cargando configuración: {str(e)}")
        sys.exit(1)


def main() -> None:
    """Punto de entrada del pipeline ETL"""

    logger.info("...Iniciando GlobalTask Data Pipeline...")

    # Cargar configuración e Instanciar y ejecutar ETL
    conf = load_config()
    etl = ETLEngineer(conf)
    etl.run()

    logger.info("...Proceso finalizado correctamente...")


if __name__ == "__main__":
    main()
