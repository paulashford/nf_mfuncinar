macsr_nf/macsr_nf_dev/README.txt
05 12 2024

This is just a simple development folder for nextflow pipeline modules for MACSMAF 
CSR networks / modules / functions /annotations etc

Output files produced by the pipeline for each method, db and cutoff:
	(KMR)1_(cpdb,humanbase,string)_0.n.tsv
		*_ranked_annotated.tsv : All signif. enrichment terms per module with GO_slim, classifcation metrics, MCC and pval_rank - which ranks p_values *per module* (ignoring source)
		*_rank_agg_final.tsv : Just the top ranked terms per module *and* source based on p_val ranks (row_rank_p) and mcc ranks (row_rank_mcc). There will be a row for each db with signif. enrichment, so up to 3 rows per module.
		*_topk_aggregated.tsv : Not sure I've sent this before - it's just the stats i.e. p_val and mcc, their ranks and the rank1 terms - might be useful for your stats Yonathan?


PYTHON SETUP
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev

# upgrades pip and setup tools within the venv
./fvp_init.sh

source ./venv/bin/activate

# setuptools (uses setup.py)
mkdir macsr_nf_dev  # this needed to exist ie /Users/ash/git/funvar/macsr_nf_dev/macsr_nf_dev
pip install -e .


# CLICK CLI
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev
source ./venv/bin/activate
macsr_nf_dev              

