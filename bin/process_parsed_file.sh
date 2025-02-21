#!/bin/bash
# process_parsed_file.sh is just a single file quick check version of bin/process_network_modules.sh
# for confirming format of previously ID converted K1 parsed module files
# p.ashford@ucl.ac.uk
# Feb 2025

# Usage: process_parsed_file.sh <input_file>

input_file=$1

# Validate inputs
if [ -z "$input_file" ] ; then
    echo "Error: Missing required parameters: $input_file" >&2
    exit 1
fi

# Debug output
echo "Processing input file: $input_file" >&2

# proc sinlge file
{
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		processed_line=$(echo "$line" | \
			tr -d "[:special:]" | \
			tr -s '[:blank:]' | \
			tr "[:space:]" '\t' | \
			sed 's/^[ \t]*//;s/[ \t]*$//')
		
		echo -e "$processed_line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
	done
} < "$input_file"
