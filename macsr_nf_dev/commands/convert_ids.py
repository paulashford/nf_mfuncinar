# Convert HGNC Ensembl entrez and other IDs using map tables
import logging
import click
import re
import pandas as pd
from pathlib import Path

import macsr_nf_dev.models.custom_click as click_opt
from macsr_nf_dev.convert_ids import conv_ids
# from macsr_nf_dev.msa import write_filtered_fasta_seqdb
from macsr_nf_dev.constants import (
    ALL_VALID_TYPES,
    MAPPING_FILE_TYPES
    # HGNC_ESSENTIAL_COLS,
    # BIOMART_VALID_TYPES
)

from macsr_nf_dev.errors import ParseError

DEFAULT_CHUNK_SIZE = 1000000

LOG = logging.getLogger()

# Custom type to convert space-delimited string to a list
class ListParamType(click.ParamType):
    name = 'list'

    def convert(self, value, param, ctx):
        # Split the string by spaces and return as a list
        return value.split()

# Create an instance of the custom type
LIST = ListParamType()

@click.command()
# @click.option(
#     "--hgnc_map_file",
#     type=click.Path(exists=True, file_okay=True, dir_okay=False, resolve_path=True),
#     # type=click.Path(exists=False, file_okay=True, dir_okay=False, writable=False, readable=True),
#     required=True,
#     help="Input: HGNC mapping file downloaded from genenames.org.",
# )
@click.option(
    "--map_file",
    type=click.Path(exists=True, file_okay=True, dir_okay=False, resolve_path=True),
    required=True,
    help="Input: Mapping file of type --map_file_type to use for ID conversion.",
)
@click.option(
    "--map_file_type",
    type=click.Choice(MAPPING_FILE_TYPES),
    default="Mapping file type.",
    required=True,
    help=f"Option: specify the mapping file type which will be used for conversion of IDs.",
)
@click.option(
    "--ids_to_convert",
    type=LIST,
    required=True,
    help=f"Input: specify IDs to convert as space separated list; all IDs should be of format --it_type.",
)
#TODO Valid id_type types should depend on MAPPING_FILE_TYPES - here just allow any selection from union of all map types.
@click.option(
    "--id_type",
    type=click.Choice(ALL_VALID_TYPES),
    default="ID type (i.e. an ID column in mapping file)",
    required=True,
    help=f"Option: specify the type of IDs present in id_list.",
)
@click.option(
    "--approved_only",
    is_flag=True, show_default=True, default=False,
    required=False,
    help="Option: Show Approved entries only.",
)
@click.option(
    "--col_filter",
    is_flag=True, show_default=True, default=False,
    required=False,
    help=f"Option: filter columns returned to a useful subset for ID mapping.",
)
@click.option(
    "--outfile",
    type=click.File("w"),
    required=True,
    help="Output: File name to output mapping file.",
)
@click.option(
    "--id_type_out",
    type=click.Choice(ALL_VALID_TYPES),
    default="ID type to return is list",
    required=True,
    help=f"Option: specify the type of IDs to return in output list. (For full mapping table, view results provided in --outfile).",
)
def convert_ids_with_mapfile(map_file, map_file_type, ids_to_convert, id_type, approved_only, col_filter, outfile, id_type_out):
    """
    Convert a list of identifiers specified in --id_list of type --id_trpe 
    using a HGNC mapping table specified in --hgnc_map_file.
    """
    LOG.info(
        f"conv_hgnc --map_file {map_file} "
        f"conv_hgnc --map_file {map_file_type} "
        f"ids_to_convert {ids_to_convert} " 
        f"id_type {id_type} "
        f"approved_only {approved_only} "
        f"col_filter {col_filter} "
        f"outfile {outfile} "
    )
    
    # convert ids to list - this is now handled via custom Click type LIST
    # id_list = re.sub(r"\s+", "", ids_to_convert, flags=re.UNICODE).split(sep=',')
    id_list =  ids_to_convert

    # map ids with HGNC file
    df_map = conv_ids(map_file, map_file_type, id_list, id_type, approved_only, col_filter)
    
    # write the full map table...
    df_map.to_csv(outfile, sep = '\t', index = False)
   
    # .. return a list of mapped IDs
    # click.echo(df_map[id_type_out].to_list())
    # may be more useful to return space-sep list...
    id_out_list = df_map[id_type_out].to_list()
    click.echo(" ".join( [str(x) for x in id_out_list]) )
    
