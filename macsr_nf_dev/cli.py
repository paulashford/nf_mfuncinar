# NOTE: This script copied / modified from CATH-AlphaFlow
# 	CATH-AlphaFlow is a Nextflow pipeline developed by CATH and the UCL Advanced Research Computing Centre. 
# 	https://github.com/UCLOrengoGroup/cath-alphaflow

import logging
import click
from macsr_nf_dev.settings import get_default_settings
from macsr_nf_dev.commands.convert_ids import convert_ids_with_mapfile
from macsr_nf_dev.commands.utils import dict_lookup
import os

os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    # level=logging.INFO, 
    level=logging.DEBUG, 
    format="%(asctime)s | %(levelname)s | %(message)s",
    filename='logs/cli_log.txt',
    filemode='w'
    # logging.basicConfig(filename='/path/to/file.log', filemode='w', level=logging.DEBUG) 
)

LOG = logging.getLogger(__name__)

@click.group()
@click.version_option()
@click.option("--verbose", "-v", "verbosity", default=0, count=True)
@click.pass_context
def cli(ctx, verbosity):
    "macsr-nf-dev workflow"

    root_logger = logging.getLogger()
    log_level = root_logger.getEffectiveLevel() - (10 * verbosity)
    root_logger.setLevel(log_level)
    LOG.info(
        f"Starting logging... (level={logging.getLevelName(root_logger.getEffectiveLevel())})"
    )

@click.command()
def dump_config():
    """
    Dump the current settings
    """
    settings = get_default_settings()
    click.echo("Settings:")
    for key, val in settings.to_dict().items():
        cli.echo(f"{key:25s} {val}")

cli.add_command(dump_config)
cli.add_command(convert_ids_with_mapfile)
cli.add_command(dict_lookup, name='dict-lookup')
