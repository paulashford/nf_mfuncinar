import click
from macsr_nf_dev.constants import (
    NET_DB_ORIGINAL_GENE_ID_TYPE_DICT,
    NET_DB_PRE_PROCESSED_GENE_ID_TYPE_DICT,
    MAPPING_TYPE_ESSENTIAL_COLS_DICT,
    NET_DICT_TYPES
)

@click.command()
@click.option('--dict_type', type=click.Choice(['net_id_type_orig', 'net_id_type_pre_proc', 'id_map_type']), 
              required=True, help='Type of dictionary to lookup')
@click.option('--dict_key', required=True, help='Key to lookup')
def dict_lookup(dict_type, dict_key):
    """Look up value in specified dictionary using dict_key as key."""
    try:
        lookup_dict = NET_DICT_TYPES[dict_type]
        if dict_key not in lookup_dict:
            raise KeyError(f"Unknown key: {dict_key}")
        click.echo(lookup_dict[dict_key], nl=False)
    except KeyError as e:
        raise click.ClickException(str(e)) 

