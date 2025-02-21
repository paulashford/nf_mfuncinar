#!/bin/bash
# p.ashford@ucl.ac.uk
# Feb 2025

# Process multiple network module files (from different edge filter thresholds) to a single, easier to parse output file, i.e.:
# <modules-ENSG-R1-string-coval-0.3.dat>
#   14 ENSG00000115325 ENSG000001
# <modules-ENSG-R1-string-coval-0.4.dat>
#   22 ENSG..c
# to single file:
#   network-modules-R1-string-0.3_14 ENSG00000115325 ENSG000001
#   network-modules-R1-string-0.3_3	ENSG00000113580	ENSG00000110711	ENSG00000163517	...
#   network-modules-R1-string-0.4_22	...

# Usage: process_network_modules.sh <method> <db> <input_dir>
# network modules ("*.dat") assumed to be in sub-directory $method, thus: search_dir="$input_dir/$method"

method=$1
db=$2
input_dir=$3

# Validate inputs
if [ -z "$method" ] || [ -z "$db" ] || [ -z "$input_dir" ] ; then
    echo "Error: Missing required parameters" >&2
    echo "Usage: process_network_modules.sh <method> <db> <input_dir>" >&2
    exit 1
fi

# search with method subsirectory 
search_dir="$input_dir/$method"

# Debug output
echo "Processing files for: method $method, db $db, input_dir $input_dir" >&2
echo "Search directory: $search_dir" >&2

# find all matching files
find "${search_dir}/" -type f -name "*${db}*.dat" -print0 |
    while IFS= read -r -d '' netfile; do
        echo "Processing file: $netfile" >&2
        # process each neqtwork file
        {
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                # Remove "1" if it appears as second field, then normalize whitespace
                # processed_line=$(echo "$line" | tr -s '[:blank:]' | tr ' ' '\t' | awk '{if ($2 == "1") $2=""; print}' | tr -s '[:blank:]')
                processed_line=$(echo "$line" | \
                    tr -d "[:special:]" | \
                    tr -s '[:blank:]' | \
                    awk '$2 == "1" {$2 = ""}; $2 == "1.0" {$2 = ""}; {print $0}' | \
                    tr "[:space:]" '\t' | \
                    tr -s '[:blank:]' | \
                    sed 's/^[ \t]*//;s/[ \t]*$//')
                
                
                # Extract module number and genes from processed line
                module_num=$(echo "$processed_line" | cut -f1)
                # genes=$(echo "$processed_line" | cut -f2- | tr -s '[:blank:]' '\t')
                genes=$(echo "$processed_line" | cut -f2-)
        
                # Create network name
                cutoff=$(basename "$netfile" | grep -o '[0-9]\.[0-9]' || echo "0.0")
                network_name="network-modules-${method}-${db}-${cutoff}_${module_num}"
                
                echo -e "${network_name}\t${genes}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'

            done          
        } < "$netfile"
    done
