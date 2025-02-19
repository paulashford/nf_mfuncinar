General notes macsmaf nf
03 02 2025 p.ashford@ucl.ac.uk

source networks
	soft links in datasets/d024 (see datasets/d024/link_files.sh)
		/K1	[original datasets/d018]
			My K1 clustering of dbs for filenames like:
				2023-04-20-185938__K1__result-modules__network-data-cpdb-coval-0.7.dat
			I ran the Monet methods on source db original IDs, so:
				NET_DB_ORIGINAL_GENE_ID_TYPE_DICT = {'cpdb': 'ensembl_gene_id', 'humanbase': 'entrez_id', 'string': 'Protein_stable_ID'}

		/M1 and /R1 - Yonathan's Monet clusters [original experiments/ey001/v03/General-Modules with subfolder M1 R1 splits by me for consistency]
			files of format:
				modules-ENSG-R1-cpdb-coval-0.9.dat
			These are all ENSG format...

macsr_nf/macsr_nf_dev/output/pre_processed_networks
	Makes simple combined cut-off module file for directory of modules by cut off and simplifies naming - i.e. 
		file names like: 
			output/pre_processed_networks/network_modules_M1_cpdb.dat
		modules like: (everything tab delim)
			network-modules-K1-cpdb-0.1_4	ENSG00000135220	ENSG00000271271
			network-modules-K1-cpdb-0.1_5	ENSG00000169962	ENSG00000173662	ENSG00000179002
	Results from running pipeline - see: output/pre_processed_networks/INFO_pre_process_20250203.txt
	with 
		params.preproc_net_modules 		= 	true
		NETWORK_PROCESSING(...) process only -  most of workflow commented out for dev
		
macsr_nf/macsr_nf_dev/output/converted_networks
	Outputs from id conversion, for example, as applied to ../pre_processed_networks/network_modules_(KMR)1_(cpdb|string|humanbase).dat
	Note: currently ad-hoc and done separately from main workflow - see notes here: ~/git/macsmaf/macsr_nf/macsr_nf_dev/workflows/id_conversion_ad_hoc.nf

macsr_nf/macsr_nf_dev/output/enrichment 
	Outputs from enrichment via g:Profiler - see base.config for params

macsr_nf/macsr_nf_dev/output/rank_annot
	Primaty outputs following rank annotation - see base.config for params
	
