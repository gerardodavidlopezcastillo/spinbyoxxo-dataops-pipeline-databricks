"""
Configuracion global de pytest

Este archivo asegura que el directorio raiz del proyecto
este disponible en el PYTHONPATH para que los imports funcionen correctamente
"""

import sys
import os

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)
