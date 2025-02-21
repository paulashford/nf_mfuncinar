GO slim pre-processing and other GO slim funcs as required
13 01 2025
git/macsmaf/macsr_nf/macsr_nf_dev

Uses GOSlim annotation pre-downloaded from [...] to simplify GO terms found from func. enrichment of a
set of PPI network modules, i.e., 
    distinct numbered sets of genes from modules (or elsewhere!) -> 
    GO:BP enrichment per module number ->
    GO-slim'd enrichment per module number (this subworkflow)
note: 
    - ports code from Dropbox/bioinf/MACSMAF/experiments/e019/process_GOslims.R
    - datasets re-downloaded for go_basic.obo and go_human.gaf as per: ash/data/funvar_pipeline/datasets/go/go_README.txt

datasets (GO, GAF, GO slim etc)
[local]:ash/data/funvar_pipeline/datasets/go/go_README.txt

mapping to slim using 
https://github.com/tanghaibao/goatools
python library:
cd git/macsmaf/macsr_nf
source venv/bin/activate
pip install goatools
note also added to: git/macsmaf/macsr_nf/macsr_nf_dev/setup.py
# pip3 install goatools --upgrade (general)
github/scripts etc:
git/bioinf/goatools

processing (NextFlow 2025)
subworkflows/mod_func_enrich/main.nf
script/go_slim.r

GObasic (rcommended for GOslim analysis)
http://purl.obolibrary.org/obo/go/go-basic.obo
/Users/ash/data/funvar_pipeline/datasets/go/go-basic.obo

GO SLIM PIR [/Users/ash/data/funvar_pipeline/datasets/go]
https://current.geneontology.org/ontology/subsets/goslim_pir.obo

GAF files [/Users/ash/data/funvar_pipeline/datasets/go]
https://current.geneontology.org/annotations/goa_human.gaf.gz
full list:
http://current.geneontology.org/products/pages/downloads.html
GAF spec is here: 
http://geneontology.org/docs/go-annotation-file-gaf-format-2.2/


example GO-slim map:
go=/Users/ash/data/funvar_pipeline/datasets/go/go-basic.obo
goslim=/Users/ash/data/funvar_pipeline/datasets/go/goslim_pir.obo
test data:
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/subworkflows/go_slim/dev
head -n 8 /Users/ash/Dropbox/bioinf/MACSMAF/datasets/d014/v3/go_bp_mod_rank_0.25_R1_string.tsv > gbprank_0.25_R1_stringtest10.txt
map:
python3 /Users/ash/git/bioinf/goatools/scripts/map_to_slim.py
 --association_file=gbprank_0.25_R1_stringtest10.txt
 ${go} ${goslim} > gbprank_0.25_R1_stringtest10_goslim.txt




NOTE: Using goatools for GO / GOslim (see above)
OWLtools [local dir see: /Users/ash/git/bioinf/owltools]
https://github.com/owlcollab/owltools/releases
specifically:
https://github.com/owlcollab/owltools/wiki/Map2Slim
local owltools (using release )
NOTE: Using goatools for GO / GOslim (see above)
    git/bioinf/owltools
    *JAR exec:
    wget https://github.com/owlcollab/owltools/releases/download/2024-06-12/owltools .
    chmod u+x owltools
    ./owltools -h | grep 'slim'
        --make-super-slim
        --map2slim
        --create-slim
    eg (from https://github.com/owlcollab/owltools/wiki/Map2Slim):
    owltools go.obo --gaf annotations.gaf --map2slim --idfile slim.terms --write-gaf annotations.mapped.gaf
    owltools go.obo --gaf annotations.gaf --map2slim --subset goslim_pombe --write-gaf annotations.mapped.gaf
    source
    git checkout tags/2024-06-12

