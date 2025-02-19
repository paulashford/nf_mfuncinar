#!/usr/bin/env Rscript
# stats_function.r 
# 20 01 2025 p.ashford@ucl.ac.uk
# https://github.com/paulashford/macsmaf_nf

# based on: experiments/e019/stats_functions.R

# TopKLists - combine rankings of p-val and mcc using rank aggregation
# Done separately for GO/KEGG/REAC as these each have sep IDs
# /Users/ash/Dropbox/_iPad/UCL/useful_ipad/useful-stats/TopKLists.pdf
# https://www.notion.so/woof7/Combining-variables-p-val-and-MCC-df64d93849cd4f688f15e677c4976beb?pvs=4
# see experiments/e019/plots/plot_pad.r
# Standardize module column names and types
standardise_columns <- function(enrichment_results) {
	if ("MCC" %in% colnames(enrichment_results)) {
		enrichment_results <- enrichment_results %>%
			mutate(MCC = as.numeric(MCC)) %>%
			rename(mcc = MCC)
	} else if (!c("mcc", "MCC") %in% colnames(enrichment_results)) {
		stop("Enrichment results must have mcc / MCC column")
	} else {
		enrichment_results <- enrichment_results %>%
			mutate(mcc = as.numeric(mcc))
	}
	return(enrichment_results)
}


aggregate_by_topk_lists <- function( enrichment_results, sources = c( "GO:BP", "KEGG", "REAC" ), agg_type = "MC3" ){
	require(TopKLists)
	source_types 	<- c( "GO:BP", "KEGG", "REAC" )
	# agg_types 		<- c( "CEMC", "MC1", "MC2", "MC3" )
	agg_types 		<- c( "MC1", "MC2", "MC3" )   # CEMC problematic with some v small lists...

	if ( !agg_type %in% agg_types ){
		print( "Agg types (see TopKLists.pdf):" )
		print( agg_types )
		return( -1 )
	}

	df_final <- standardise_columns(enrichment_results)

	# add ranks to the two types of score per source (mcc and p-val) 
	# note: row_number has no tied ranks
	drp <- df_final %>% 
		group_by( network_method, network_db, network_cutoff, experiment_info, module, source ) %>%
		mutate( row_rank_p = row_number( p_value ) ) %>%
		mutate( row_rank_mcc = row_number( desc( mcc ) ) ) %>%
		select(network_method, network_db, network_cutoff, experiment_info, 
				module, source, term_id, p_value, row_rank_p, mcc, row_rank_mcc, term_name)
		# select(  module, monet_type, experiment_info, source, term_id, p_value, row_rank_p, mcc, row_rank_mcc, term_name )

	drp <- mutate( drp, top_go = '-' )
	drp <- mutate( drp, top_kegg = '-' )
	drp <- mutate( drp, top_reac = '-' )

	for ( this_source in sources ){
		print('>source')
		print(this_source)
		# Get space of all terms for this KEGG/REAC/GO
		df_filt <- drp %>%
			filter( source == this_source )
		spaceall <- unique( df_filt$term_id )
		# print(spaceall)

		# Analyse each module
		for ( mod in unique( drp$module ) ) {
			print( mod )
			print( this_source )
			print('>mod')

			df_filt <- filter( drp, source == this_source & module == mod )
			print(dim(df_filt))
			if (nrow(df_filt)> 1 ){
		
				input_p		<- arrange( df_filt, row_rank_p )
				input_mcc 	<- arrange( df_filt, row_rank_mcc )

				input		<- list( input_p$term_id, input_mcc$term_id )
				space		<- list( spaceall, spaceall )
				
				agg.mc		<- MC( input, space )
				# agg.cemc	<- CEMC( input , space )

				# agg=list( MC1=agg.mc$MC1.TopK, MC2=agg.mc$MC2.TopK, MC3=agg.mc$MC3.TopK, CEMC=agg.cemc$TopK)
				agg			<- list( 	MC1=agg.mc$MC1.TopK, MC1P=agg.mc$MC1.Prob,
										MC2=agg.mc$MC2.TopK, MC2P=agg.mc$MC2.Prob,
										MC3=agg.mc$MC3.TopK, MC3P=agg.mc$MC3.Prob
									)
				print(head(do.call(cbind, agg )))

				# Return 1st overall rank, or the top mcc if all top ranked equal
				top_term 	<- agg$MC3[[1]]
				print('TOP  ')	
				print(top_term)
				print(' ')
				print('VAR:')
				var_test <- var(agg$MC3P) < 1e-25
				print( var_test )
				print( var(agg$MC3P) )

				print('DIFF:')
				diff12_test <- (agg$MC3P[[1]] - agg$MC3P[[2]]) < 1e-10
				print( diff12_test )
				print( diff12_test )

				# if tied 1/2 between p and mcc just take mcc (will be more specific terms, I think)
				if ( diff12_test ){
					top_row 	<- filter(df_filt, row_rank_mcc ==1 )
					top_term 	<- top_row$term_id
				}
				print('FINAL TOP  ')	
				print(top_term)

			}else if (nrow(df_filt)== 1) {
			   print(paste0("SINGLE ", this_source, " in module ", str(mod)))
			   top_term 	<- df_filt$term_id
			   print('FINAL TOP  ')	
			   print(top_term)
			}
			else{
				print(paste0("No ", this_source, " in module ", str(mod)))
				top_term 	<- '-'
			    print('FINAL TOP  ')	
			    print(top_term)
			}

			# UPDATE DF
			if ( this_source == "GO:BP" ){ drp$top_go[drp$source == this_source & drp$module == mod] <- top_term }
			if ( this_source == "KEGG" ){ drp$top_kegg[drp$source == this_source & drp$module == mod] <- top_term }
			if ( this_source == "REAC" ){ drp$top_reac[drp$source == this_source & drp$module == mod] <- top_term }

			print('<mod  ')	
			print(' ')
			print(' ')
		}
		
		print('<this_source  ')
		print(' ')
		print(' ----------------------- ')
		print(' ')
	}

return(drp)

}
