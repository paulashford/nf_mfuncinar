# NOTE: This script based on CATH-AlphaFlow
# 	CATH-AlphaFlow is a Nextflow pipeline developed by CATH and the UCL Advanced Research Computing Centre. 
# 	https://github.com/UCLOrengoGroup/cath-alphaflow

import logging
from pathlib import Path
from prettyconf import config

DEFAULT_AF_VERSION = 4
DEFAULT_AF_FRAGMENT = 1

PROJECT_ROOT_DIR = Path(__file__).parent.parent

LOG = logging.getLogger(__name__)

def resolve_path(raw_path_str):
    return str(Path(raw_path_str).resolve())

class Settings:
    # CONSTANTS_GO_HERE = <....>
    
    def to_dict(self):
        dict = {}
        for key in dir(self):
            if key.startswith("__"):
                continue
            val = getattr(self, key)
            if callable(val):
                continue
            if "PASSWORD" in key:
                val = "******"
            dict[key] = val
        return dict

class ProductionSettings(Settings):
    pass

class TestSettings(Settings):
    # CONSTANTS_GO_HERE = <....>
    # ORACLE_DB_HOST = "TEST_ORACLE_DB_HOST"
	pass

def get_default_settings():
    LOG.info("Using default settings")
    return ProductionSettings()

def get_test_settings():
    LOG.info("Using test settings")
    return TestSettings()
