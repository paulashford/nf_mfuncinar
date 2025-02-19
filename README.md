**NextFlow pipeline for g:Profiler[1]-based functional enrichment of gene sets from PPI network modules.**

*Under development as a component for a manuscript in prep (Goldtzvik,Y., Ashford P. et al, in prep.) and currently licenced under Apache v2.0.*

Pipeline runs functional enrichments of module gene-sets, followed by GO-slim analysis using GOATOOLS[2], module annotations, and ranking based on Matthew's Correlation Coefficient and g:Profiler enrichment p-values. Outputs of the top ranked terms for each module are also identified using TopKLists[3].

Module detection on protein-protein interaction networks used MONET tool[4] [https://github.com/BergmannLab/MONET] based on DREAM module detection challenge[5]. Human PPI networks from STRING[6], ConsensusPathDB[7], and HumanBase[8]. We ran g:Profiler enrichment with terms referencing KEGG[9], Reactome[10] and GO:BP[11].

**References**

[1] Raudvere, U. et al. g:Profiler: a web server for functional enrichment analysis and conversions of gene lists (2019 update). Nucleic Acids Research 47, W191–W198 (2019).

[2] Klopfenstein, D. V. et al. GOATOOLS: A Python library for Gene Ontology analyses. Sci Rep 8, 10872 (2018).

[3] Schimek, M. G. et al. TopKLists: a comprehensive R package for statistical inference, stochastic aggregation, and visualization of multiple omics ranked lists. Stat Appl Genet Mol Biol 14, 311–316 (2015).

[4] Tomasoni, M. et al. MONET: A Toolbox Integrating Top-Performing Methods for Network Modularisation. 611418 https://www.biorxiv.org/content/10.1101/611418v4 (2019) doi:10.1101/611418.

[5] Choobdar, S. et al. Assessment of network module identification across complex diseases. Nat Methods 16, 843–852 (2019).

[6] Szklarczyk, D. et al. The STRING database in 2023: protein-protein association networks and functional enrichment analyses for any sequenced genome of interest. Nucleic Acids Res 51, D638–D646 (2023).

[7] Kamburov, A., Stelzl, U., Lehrach, H. & Herwig, R. The ConsensusPathDB interaction database: 2013 update. Nucleic Acids Research 41, D793–D800 (2013).

[8] Greene, C. S. et al. Understanding multicellular function and disease with human tissue-specific networks. Nat Genet 47, 569–576 (2015).

[9] Kanehisa, M., Sato, Y. & Kawashima, M. KEGG mapping tools for uncovering hidden features in biological data. Protein Sci 31, 47–53 (2022).

[10] Jassal, B. et al. The reactome pathway knowledgebase. Nucleic Acids Research 48, D498–D503 (2020).

