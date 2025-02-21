#!/bin/bash
# simple ad-hoc pre-proc module runner
# for tests & checks see bin/test_process_network_modules.sh

declare -x user_root_dir='/Users/ash'
declare -x input_dir="${user_root_dir}/Dropbox/bioinf/MACSMAF/datasets/d024"
declare -x output_dir="${user_root_dir}/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v02/pre_processed_networks"

# declare -x db='cpdb'
# declare -x db='string'
declare -x db='humanbase'
# declare -x method='M1'
# declare -x method='R1'
declare -x method='K1'

# cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin
./process_network_modules.sh $method $db $input_dir > "${output_dir}/network_modules_${method}_${db}_parsed.dat"

# REMOVE K1 MODULES WITH FEWER THAN 3 GENES
cd "${output_dir}"
mkdir -p k1_no_colnum_filter
mv network_modules_K1_cpdb_parsed.dat k1_no_colnum_filter/
mv network_modules_K1_string_parsed.dat k1_no_colnum_filter/
mv network_modules_K1_humanbase_parsed.dat k1_no_colnum_filter/

awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_cpdb_parsed.dat > network_modules_K1_cpdb_parsed.dat
awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_string_parsed.dat > network_modules_K1_string_parsed.dat
awk -F'\t' 'NF >3' k1_no_colnum_filter/network_modules_K1_humanbase_parsed.dat > network_modules_K1_humanbase_parsed.dat

