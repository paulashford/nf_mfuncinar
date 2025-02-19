#!/bin/bash

# Process network modules script
# Usage: process_network_modules.sh <method> <db> <input_dir>

method=$1
db=$2
input_dir=$3

# Validate inputs
if [ -z "$method" ] || [ -z "$db" ] || [ -z "$input_dir" ] ; then
    echo "Error: Missing required parameters" >&2
    echo "Usage: process_network_modules.sh <method> <db> <input_dir>" >&2
    exit 1
fi

# Debug output
echo "Processing files for method=$method db=$db in directory=$input_dir" >&2
echo "Directory contents:" >&2
ls -la "$input_dir" >&2

# Get the network modules files for given method and db
echo "Finding files matching pattern: *${db}*.dat" >&2
find "$input_dir" -name "*${db}*.dat" -type f | while read -r file; do
    echo "Processing file: $file" >&2
    
    # Extract module number and genes from each line
    while read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        if [ "$method" = "K1" ] ; then
            # Process the line to remove second column (1.0) and convert spaces to tabs
            processed_line=$(echo "$line" | awk '!($2 = "")' | tr -s '[:blank:]' | tr ' ' '\t')
        elif [ "$method" = "M1" ] || [ "$method" = "R1" ] ; then
            processed_line=$(echo "$line" | tr -s '[:blank:]' | tr ' ' '\t')
        else
            stop "bad method passed $method"
        fi
        
        
        # Extract module number and genes from processed line
        module_num=$(echo "$processed_line" | cut -f1)
        genes=$(echo "$processed_line" | cut -f2-)
        
        # Create network name
        cutoff=$(basename "$file" | grep -o '[0-9]\.[0-9]' || echo "0.0")
        network_name="network-modules-${method}-${db}-${cutoff}_${module_num}"
        
        # Output the network module and its genes
        echo -e "${network_name}\t${genes}"
        
    done < "$file"
done
