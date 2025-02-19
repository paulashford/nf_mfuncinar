# go_slim.r
# 17 01 2025
# simply return module num and concatenated GO terms for top ranked
# use for input to GOAtools for slims

library(optparse)
library(tidyr)
library(dplyr)

# Get debug setting from environment variable
debug_mode <- as.logical(Sys.getenv("DEBUG", "FALSE"))

# Parse command line arguments
option_list <- list(
    make_option("--input", type="character", help="Input RDS file path for enrichment results"),
    make_option("--min_perc_rank", type="numeric", default=0.25, help="Minimum percentage rank cutoff [default=0.25]"),
    make_option("--output", type="character", help="Output file path for GO slim results")
)

opt <- parse_args(OptionParser(option_list=option_list))

# Get top ranked GO:BP terms for each module (these wil be SLIMed)
get_top_go_terms_by_module <- function(gpr, min_perc_rank=0.25) {
    # Validate input data
    if (!("perc_rank" %in% colnames(gpr))) {
        if(debug_mode) {
            stop("Required column 'perc_rank' not found in input data. Available columns: ", 
                 paste(colnames(gpr), collapse=", "))
        } else {
            stop("Required column 'perc_rank' not found in input data.")
        }
    }
    
    go_bp_mod <- gpr %>%
        ungroup() %>%
        filter(source == "GO:BP") %>%
        filter(perc_rank <= min_perc_rank) %>% 
        select(func_module_number, term_id) %>%
        group_by(func_module_number) %>%
        summarise(lst = paste0(term_id, collapse = ";"), .groups = "keep")
    
    return(go_bp_mod)
}

# Main execution
main <- function() {
    # Read RDS input file
    enrichment_data <- readRDS(opt$input)
    
    # Process the data
    results <- get_top_go_terms_by_module(enrichment_data, opt$min_perc_rank)
    
    # Write results to file
    write.table(results, 
                file = opt$output, 
                sep = "\t", 
                row.names = FALSE, 
                quote = FALSE)
}

# Run main function
main()