# constants.py
# Feb 25; p.ashford@ucl.ac.uk
# Lists and dicts for PPI network types, genes IDs, ID mapping files etc

HGNC_VALID_TYPES = ['entrez_id', 'ensembl_gene_id', 'hgnc_id', 'symbol', 'refseq_accession' ]
HGNC_ESSENTIAL_COLS = ['hgnc_id', 'symbol', 'locus_group', 'name', 'status', 'entrez_id', 'ensembl_gene_id', 'refseq_accession', 'alias_symbol', 'prev_symbol']
BIOMART_VALID_TYPES = ['Gene_stable_ID', 'Gene_stable_ID_version', 'Transcript_stable_ID', 'Transcript_stable_ID_version', 'Protein_stable_ID', 'Protein_stable_ID_version', 'NCBI_gene_ID', 'Gene_description', 'HGNC_ID', 'UniProtKB_ID']
BIOMART_ESSENTIAL_COLS = ['Gene_stable_ID', 'Transcript_stable_ID', 'Protein_stable_ID', 'NCBI_gene_ID', 'Gene_description', 'HGNC_ID', 'UniProtKB_ID']
UNIPROTKB_VALID_TYPES = ['UniProtKB-AC', 'UniProtKB-ID', 'EntrezGeneID', 'RefSeq', 'GI', 'PDB', 'GO', 'UniRef100', 'UniRef90', 'UniRef50', 'UniParc', 'PIR', 'NCBI-taxon', 'MIM', 'UniGene', 'PubMed', 'EMBL', 'EMBL-CDS', 'Ensembl', 'Ensembl_TRS', 'Ensembl_PRO', 'Additional_PubMed']
ALL_VALID_TYPES = HGNC_VALID_TYPES + BIOMART_VALID_TYPES + UNIPROTKB_VALID_TYPES
MAPPING_FILE_TYPES = ['hgnc', 'biomart', 'uniprotkb']
MAPPING_TYPE_ESSENTIAL_COLS_DICT = {'hgnc': HGNC_ESSENTIAL_COLS, 'biomart': BIOMART_ESSENTIAL_COLS}

# original gene id type in source database (id_conversion/id_conversion_ad_hoc.nf; params.input_network_file_type = 'original')
NET_DB_ORIGINAL_GENE_ID_TYPE_DICT = {'cpdb': 'ensembl_gene_id', 'humanbase': 'entrez_id', 'string': 'Protein_stable_ID'}
# pre-processed gene id type (note: for K1 humanbase and string, gene ID conversion was done via subworkflows/id_conversion/id_conversion_ad_hoc.nf)
NET_DB_PRE_PROCESSED_GENE_ID_TYPE_DICT = {'cpdb': 'ensembl_gene_id', 'humanbase': 'ensembl_gene_id', 'string': 'ensembl_gene_id'}

NET_DICT_TYPES = {
    'net_id_type_orig': NET_DB_ORIGINAL_GENE_ID_TYPE_DICT,
    'net_id_type_pre_proc': NET_DB_PRE_PROCESSED_GENE_ID_TYPE_DICT,
    'id_map_type': MAPPING_TYPE_ESSENTIAL_COLS_DICT
}