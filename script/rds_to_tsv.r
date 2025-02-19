#!/usr/bin/env Rscript
# rds_to_tsv.r
# Simple utility to convert RDS files to TSV format
# Usage: Rscript rds_to_tsv.r input.rds output.tsv

# Load required libraries
library(tidyverse)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
    stop("Required arguments: input_rds output_tsv")
}

input_rds <- args[1]
output_tsv <- args[2]

# Read RDS and convert to TSV
data <- readRDS(input_rds)

# Check if data is a data frame or can be coerced to one
if (!is.data.frame(data) && !is.matrix(data)) {
    stop("Input RDS must contain a data frame or matrix")
}

# Convert to tibble if not already
data <- as_tibble(data)

# Write to TSV
write_tsv(data, output_tsv)

# Print confirmation
cat(sprintf("Converted %s to %s\n", input_rds, output_tsv)) 