# Convert ID formats for genes / proteins used in network dbs
# 04 12 2024 [original version in experiments/e023 - moved to NextFlow project dir 09 12 2024]
# import pandas as pd
# import pathlib
from macsr_nf_dev.constants import (
    ALL_VALID_TYPES,
    HGNC_ESSENTIAL_COLS,
    BIOMART_ESSENTIAL_COLS,
    MAPPING_TYPE_ESSENTIAL_COLS_DICT,
    NET_DB_ORIGINAL_GENE_ID_TYPE_DICT
)
from macsr_nf_dev.errors import (
    ParseMapFileError,
    DelimeterError
)
import pandas as pd
import logging
LOG = logging.getLogger(__name__)

def conv_ids(map_file, map_file_type, id_list, id_type, approved_only, col_filter):
    # check thd id_type
    if not id_type in ALL_VALID_TYPES:
        return(print("id_type must be one of: " + ", ".join(str(x) for x in ALL_VALID_TYPES)))
    
    # convert id_list to DataFrame
    df_id = pd.DataFrame(data = id_list, columns = [id_type], dtype=object)
    
    # Parse mapping file
    try:
        df_map = pd.read_csv(map_file, sep = '\t', dtype=object)
    except:
        raise ParseMapFileError(f"Failed to parse map file ({map_file}) as Pandas.DataFrame.")
    if df_map.columns.size == 1:
        raise DelimeterError(f"Parsing of map file ({map_file}) resulted in only 1 column - check map file is tab-delimeted.")
    
    # HGNC status filter
    if approved_only & (map_file_type == 'hgnc'):
        df_map[df_map['status'] == 'Approved']
        
    # Mapping: merge id_list and HGNC - left join will return all the passed IDs even if no matches in HGNC
    df_merge = pd.merge(df_id, df_map, on = id_type, how = "left")
    # Apply col filter
    if col_filter:
        df_merge = df_merge[MAPPING_TYPE_ESSENTIAL_COLS_DICT[map_file_type]]
    
    return(df_merge)
    