Functional enrichment pipeline using updated M1 and R1 source modules provided by Yonathan
05 03 2025

Notes:
1. symlinks changed via ~/Dropbox/bioinf/MACSMAF/datasets/d024/link_files.sh
	/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024/K1/k1 -> /Users/ash/Dropbox/bioinf/MACSMAF/datasets/d018/k1
	/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024/M1/M1 -> /Users/ash/Dropbox/bioinf/MACSMAF/experiments/ey001/v04/M1
	/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024/R1/R1 -> /Users/ash/Dropbox/bioinf/MACSMAF/experiments/ey001/v04/R1
2. New modules linked from ~/Dropbox/bioinf/MACSMAF/experiments/ey001/v04 use original gene IDs - we have decided to keep this for these runs 
3. NETWORK_PROCESSING process has a workflow issue. To save time, this step is easy to do manually, eg:
cd /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/bin
export input_dir='/Users/ash/Dropbox/bioinf/MACSMAF/datasets/d024'
export out_dir='/Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/pre_processed_networks'
export method="M1"	#export method="R1"	#export method="K1"
export db="string"	#export db="cpdb"	#export db="humanbase"
./process_network_modules.sh $method $db $input_dir > "${out_dir}/tmp/network_modules_${method}_${db}_parsed_all.dat"
awk -F'\t' 'NF >3' "${out_dir}/tmp/network_modules_${method}_${db}_parsed_all.dat" > "${out_dir}/network_modules_${method}_${db}_parsed.dat"
	finally: cp *.dat /Users/ash/git/macsmaf/macsr_nf/macsr_nf_dev/output/compiled_module_datasets/v03/pre_processed_networks
		ensure 	params.preproc_net_modules 		= 	false
		and 	params.nf_network_modules_dir		= 	"${params.nf_out_dir}/compiled_module_datasets/v03/pre_processed_networks"
