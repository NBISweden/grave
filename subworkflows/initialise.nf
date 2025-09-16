/* 
----------------------------------------------------------------------------------------
Initialisation subworkflow
----------------------------------------------------------------------------------------
*/

workflow INITIALISE {

	main:

		// Help message

			if (params.help) {
				println (" ")
				println ("grave")
				println (" ")
				println ("Command line parameters [default option within square brackets]:")
				println (" ")
				println ("General settings:")
				println (" ")
				println ("--account [${params.account}]					Used only for the SLURM executor, provide an allocation name for hours billing.")
				println ("--email_report [${params.email_report}]					Receive an email on pipeline completion.")
				println ("--email [${params.email}]						Email address for report.")
				println (" ")
				println ("Input settings:")
				println (" ")
				println ("--graphMode [${params.graphMode}]					Use personal pangenomes (haplo), or filtered graphs (filter). See main docs or Minigraph-Cactus docs for more info.")
				println ("--multiRef [${params.multiRef}]					Tell grave to use provided '.paths' files containing lists of reference sample paths (not required for graphs containing only one reference sample).")
				println ("--graphDir				 		Path to the directory containing a '.gbz' file.")
				println ("--samplesheet				 		Path to the samplesheet file.")
				println ("--pathsDir				 		Path to the directory containing '.paths' files.")
				println (" ")
				println ("Optional processes:")
				println (" ")
				println ("--profilePMD [${params.profilePMD}]					Turn off post-mortem damage profiling for ancient samples (true/false).")
				println ("--graphDeconstruct [${params.graphDeconstruct}]				Produce VCF of variants in the graph, or skip (true/false).")
				println ("--vgGenotype [${params.vgGenotype}]					Genotype graph variants in mapped samples with vg call (true/false).")
				println ("--freeBayes [${params.freeBayes}]					Call variants in mapped samples with FreeBayes (true/false).")
				println ("--deepVariant [${params.deepVariant}]					Call variants in mapped samples with DeepVariant (true/false), recommended true for human data.")
				println (" ")
				println ("Indexing parameters:")
				println (" ")
				println ("--noNestedDistance [${params.noNestedDistance}]				If the graph is complex, distance index construction may require excessive amounts of memory. Setting true produces a limited version of the index and reduces memory imprint, use for debugging purposes (true/false).")
				println (" ")
				println ("Haplotype subsampling parameters:")
				println (" ")
				println ("--aDNAkmerHaplSubSam [${params.aDNAkmerHaplSubSam}]				K value when K-mer profiling ancient DNA samples for haplotype subsampling.")
				println ("--aDNAwindowHaplSubSam [${params.aDNAwindowHaplSubSam}]				Window size when constructing '.hapl' index for ancient DNA samples.")
				println ("--modernKmerHaplSubSam [${params.modernKmerHaplSubSam}]				K value when K-mer profiling modern samples for haplotype subsampling.")
				println ("--modernWindowHaplSubSam [${params.modernWindowHaplSubSam}]				Window size when constructing '.hapl' index for modern samples.")
				println (" ")
				println ("Filtered graph minimizer construction parameters:")
				println (" ")
				println ("--aDNAkmerMinimizer [${params.aDNAkmerMinimizer}]				K value when constructing minimizer indexes for ancient DNA samples.")
				println ("--aDNAwindowMinimizer [${params.aDNAwindowMinimizer}]				Window size when constructing minimizer indexes for ancient DNA samples.")
				println ("--modernKmerMinimizer [${params.modernKmerMinimizer}]				K value when constructing minimizer indexes for modern samples.")
				println ("--modernWindowMinimizer [${params.modernWindowMinimizer}]				Window size when constructing minimizer indexes for modern samples.")
				println (" ")
				println ("FASTP parameters:")
				println (" ")
				println ("--discardUnmerged [${params.discardUnmerged}]				Discard unmerged reads when merging aDNA paired-end FASTQ files (true/false). If retained, unmerged reads are later combined with merged in a single FASTQ.")
				println ("--fastpDedup [${params.fastpDedup}]					If true, duplicate reads detected by exact hash matching algorithm are removed by FASTP (true/false).")
				println ("--dupCalcAccuracy [${params.dupCalcAccuracy}]					Accuracy level to calculate duplication rate (1~6). Higher level uses more memory to avoid hash collision (1G, 2G, 4G, 8G, 16G, 24G). If --fastpDedup = true, 3+ recommended. If false, 1 recommended.")
				println ("--readDiscardLength [${params.readDiscardLength}]				Reads shorter than INT will be discarded.")
				println (" ")
				println ("Mapping parameters:")
				println (" ")
				println ("--gamDiscardUnmapped [${params.gamDiscardUnmapped}]				Discard unmapped reads when filtering GAM files (true/false).")
				println ("--gamFilterMapQ [${params.gamFilterMapQ}]					Apply MAPQ filtering when processing GAM files. Theshold value is set by --minimumMapQFilter (true/false).")
				println ("--kffKmerMinimum [${params.kffKmerMinimum}]					Minimum required occurences for a K-mer to be counted during read analysis prior to haplotype subsampling.")
				println ("--minimumScorePrimaryAlign [${params.minimumScorePrimaryAlign}]			Fraction identity required to keep primary alignment during filtering (0-1).")
				println ("--minimumMapQFilter [${params.minimumMapQFilter}]				Filter alignments with mapping quality < INT. Requires --gamFilterMapQ to be set.")
				println ("--keepRawGam [${params.keepRawGam}]					Output the raw GAM files, not just filtered.")
				println (" ")
				println ("BAM deduplication:")
				println (" ")
				println ("--duplicateTaggingPolicy [${params.duplicateTaggingPolicy}]			Policy for tagging duplicates in the DT optional SAM/BAM field (DontTag, OpticalOnly, All). Irrelevant if --removeDuplicates is true. See Picard docs for more info.")
				println ("--dedupConsiderBothEnds [${params.dedupConsiderBothEnds}]				If true, for aDNA samples Picard MarkDuplicates will consider both 5' and 3' ends of reads when identifying duplicates. If false, only the 5' end will be considered (true/false).")
				println ("--removeDuplicates [${params.removeDuplicates}]				If true, Picard MarkDuplicates will not write duplicate reads to the output. If false, they will be written with duplicate flags set and tagging policy applied (true/false).")
				println (" ")
				println ("General variant calling parameters:")
				println (" ")
				println ("--maxNestLevel [${params.maxNestLevel}]					Maximum variant nest level. Discards VCF variants over this level from vg deconstruct and vg genotype outputs, unless the variant is found within a popped feature, i.e., reference allele length was over --maxRefLength (${params.maxRefLength}). Does not affect raw VCF output.")
				println ("--maxRefLength [${params.maxRefLength}]					Maximum reference allele size. Pops/discards VCF variants if the reference allele is over this value, retaining variants nested within the popped variant (even if they are nested above --maxNestLevel). Applies to vg deconstruct and vg genotype outputs, does not affect raw VCF output.")
				println ("--samplePloidy [${params.samplePloidy}]					Sample ploidy.")
				println ("--minimumAlleleSupport [${params.minimumAlleleSupport}] 				Minimum allele support for a call.")
				println ("--keepRawVcf [${params.keepRawVcf}]					Output the raw VCF files, not just filtered/normalised.")
				println (" ")
				println ("vg deconstruct parameters:")
				println (" ")
				println ("--deconstructNestedSnarls [${params.deconstructNestedSnarls}]			When false, vg deconstruct outputs only top-level sites, not nested sites. Setting to true will output a site for all snarls spanned by a reference path (true/false)")
				println (" ")
				println ("vg genotype parameters:")
				println (" ")
				println ("--minimumSiteSupport [${params.minimumSiteSupport}]				Minimum site support for a call.")
				println ("--baselineErrorSmallVariants [${params.baselineErrorSmallVariants}]			Baseline error rates for Poisson model for small variants.")
				println ("--baselineErrorLargeVariants [${params.baselineErrorLargeVariants}]			Baseline error rates for Poisson model for large variants.")
				println (" ")
				println ("FreeBayes parameters:")
				println (" ")
				println ("--maxComplexGap [${params.maxComplexGap}]					Maximum distance between polymorphisms on the same read.")
				println ("--minFraction [${params.minFraction}]					Require at least this fraction of observations supporting an alternate allele within a single individual in the in order to evaluate the position.")
				println (" ")
				println ("DeepVariant parameters:")
				println (" ")
				println ("--deepVariantModelType [${params.deepVariantModelType}]				WGS/WES/PACBIO/ONT_R104/HYBRID_PACBIO_ILLUMINA")
				println (" ")
				println ("Help:")
				println (" ")
				println ("--tracing [${params.tracing}]					Enable trace reports for the workflow, including timeline, report, trace, and dag files (in ${projectDir}/tracing).")
				error ("--help							Print this message.")
			}

		// Early error if email requested but address not provided

			if (params.email_report && !params.email) {
				error ("ERROR: Email reporting requested but no email address provided, please provide an email address with '--email'.")
			}

		// Nextflow version

			if (!nextflow.version.matches('>=25.04.6')) {
				error ("ERROR: This workflow asks for Nextflow version '>=25.04.6'. You are running '${nextflow.version}'. Consider using the provided pixi environment.")
			}

		// Apptainer executable

			if (!"apptainer".execute().text.trim()) {
				error ("ERROR: This workflow requires Apptainer. To run using the pixi apptainer environment, add '-e apptainer' to your pixi run command.")
			}

		// Check directory structure

			if (!file("${params.graphDir}").isDirectory()) {
				println("ERROR: Pangenome directory '${params.graphDir}' was not found. Creating it and exiting. Please add or link to the graph there (see docs).")
				file("${params.graphDir}").mkdirs()
				error ("Created '${params.graphDir}'.")
			}

		// Warn about process settings

		// Deduplication

			if (!(params.duplicateTaggingPolicy.toString() in ["DontTag", "OpticalOnly", "All"])) {
				error ("ERROR: Invalid value '${params.duplicateTaggingPolicy}' for '--duplicateTaggingPolicy' parameter. Please specify either 'DontTag', 'OpticalOnly' or 'All' (case sensitive).")
			}

		// Graph call

			if (params.graphDeconstruct.toString().toLowerCase() in ["true", "false"]) {
				boolean graphDeconstructEnabled = params.graphDeconstruct.toString().toLowerCase() == "true"
				if (!graphDeconstructEnabled) {
					println ("USER NOTE: Genotyping directly from the graph is disabled.")
				}
			} else {
				error ("ERROR: Invalid value '${params.graphDeconstruct}' for '--graphDeconstruct' parameter. Please specify either 'true' or 'false' (case insensitive).")
			}

		// Vg map call

			if (params.vgGenotype.toString().toLowerCase() in ["true", "false"]) {
				boolean vgGenotypeEnabled = params.vgGenotype.toString().toLowerCase() == "true"
				if (!vgGenotypeEnabled) {
					println ("USER NOTE: Genotyping with vg call is disabled.")
				}
			} else {
				error ("ERROR: Invalid value '${params.vgGenotype}' for '--vgGenotype' parameter. Please specify either 'true' or 'false' (case insensitive).")
			}

		// DeepVariant

			if (params.deepVariant.toString().toLowerCase() in ["true", "false"]) {
				boolean deepVariantEnabled = params.deepVariant.toString().toLowerCase() == "true"
				if (!deepVariantEnabled) {
					println ("USER NOTE: Variant calling with DeepVariant is disabled.")
				}
			} else {
				error ("ERROR: Invalid value '${params.deepVariant}' for '--deepVariant' parameter. Please specify either 'true' or 'false' (case insensitive).")
			}

		// FreeBayes

			if (params.freeBayes.toString().toLowerCase() in ["true", "false"]) {
				boolean freeBayesEnabled = params.freeBayes.toString().toLowerCase() == "true"
				if (!freeBayesEnabled) {
					println ("USER NOTE: Variant calling with FreeBayes is disabled.")
				}
			} else {
				error ("ERROR: Invalid value '${params.freeBayes}' for '--freeBayes' parameter. Please specify either 'true' or 'false' (case insensitive).")
			}

		// Compute snarls (only if both graph genotyping and vg call genotyping are disabled)

			if (params.graphDeconstruct.toString().toLowerCase() && params.vgGenotype.toString().toLowerCase() in ["true", "false"]) {
				boolean graphAndVgCallDisabled = params.graphDeconstruct.toString().toLowerCase() == "false" && params.vgGenotype.toString().toLowerCase() == "false"
				if (graphAndVgCallDisabled) {
					println ("USER NOTE: Since the graph and vg call genotypers are disabled, snarls will also not be computed.")
				}
			}

		// Remind user of reference sample setting

			if (!params.multiRef) {
				println ("USER NOTE: As grave was not configured to take paths files, it will assume a single reference sample is present in your graph.")
			}

		// Check for graph files (different inputs depending on 'haplo' or 'filter' modes)

			// Defines the expected graph file patterns
			def graphDir = new File ("${params.graphDir}")
			def haplPattern = ~/.*\.hapl$/
			def gbzPattern = ~/.*\.gbz$/
			def distPattern = ~/.*\.dist$/
			def minPattern = ~/.*\.min$/
			def gbzFilteredPattern = ~/.*\.d.*\.gbz$/
			def foundHapl = graphDir.listFiles().findAll { it.isFile() && it.name =~ haplPattern }
			def foundGbz = graphDir.listFiles().findAll { it.isFile() && it.name =~ gbzPattern }
			def foundDist = graphDir.listFiles().findAll { it.isFile() && it.name =~ distPattern }
			def foundMin = graphDir.listFiles().findAll { it.isFile() && it.name =~ minPattern }
			def foundFilteredGbz = graphDir.listFiles().findAll { it.isFile() && it.name =~ gbzFilteredPattern }

			// Haplo mode uses the clipped unfiltered graph (i.e. no file pattern matching a filtered graph)
			if ("${params.graphMode}" == "haplo") {

				if (!foundHapl.isEmpty()) {
					println ("USER NOTE: grave will not use the '.hapl' file(s) in '${params.graphDir}'.")
				}

				if (foundGbz.isEmpty()) {
					error ("ERROR: No '.gbz' file found (please see docs).")
				}

				if (foundGbz.size() > 1) {
					error ("ERROR: More than one '.gbz' file found in '${params.graphDir}'. For 'haplo' mode provide only the clipped unfiltered graph.")
				}

				if (!foundFilteredGbz.isEmpty()) {
					error ("ERROR: The '.gbz' file found in '${params.graphDir}' looks like a filtered graph by its name structure. For 'haplo' mode provide a clipped unfiltered graph.")
				}

				// Dist and min files suggest wrong inputs have been provided, so these will throw an error.
				if (!foundDist.isEmpty()) {
					error ("ERROR: The '.dist' file in '${params.graphDir}' is not required in haplo mode and suggests a filtered graph is present (see docs).")
				}

				if (!foundMin.isEmpty()) {
					error ("ERROR: The '.min' file in '${params.graphDir}' is not required in haplo mode and suggests a filtered graph is present (see docs).")
				}

			// Filter mode uses the clipped filtered graph
			} else if ("$params.graphMode" == "filter") {

				if (!foundHapl.isEmpty()) {
					error ("ERROR: Graph mode is 'filter' but a '.hapl' index was found suggesting an unfiltered graph (see docs).")
				}

				if (foundGbz.isEmpty()) {
					error ("ERROR: No '.gbz' file found (please see docs).")
				}

				if (foundGbz.size() > 1) {
					error ("ERROR: More than one '.gbz' file found in '${params.graphDir}'. For 'filter' mode provide a clipped and filtered graph.")
				}

				if (foundFilteredGbz.isEmpty()) {
					error ("ERROR: The .gbz file found in '${params.graphDir}' does not look like a filtered graph by its name structure. For 'filter' mode provide the clipped filtered graph.")
				}

				if (!foundDist.isEmpty()) {
					println ("USER NOTE: grave will not use the '.dist' file in '${params.graphDir}'.")
				}

				if (!foundMin.isEmpty()) {
					println ("USER NOTE: grave will not use the '.min' file(s) in '${params.graphDir}'.")
				}

			// Prompt the user if there is a typo in the graph mode param
			} else {
				error ("ERROR: Graph mode parameter '${params.graphMode}' not recognised, accepts 'haplo' or 'filter' (please see docs).")
			}

		// Check for files specifying reference paths

			def pathsDir = new File ("${params.pathsDir}")
			def pathsPattern = ~/.*\.paths$/
			def foundPaths = pathsDir.listFiles().findAll { it.isFile() && it.name =~ pathsPattern }

			if (foundPaths.isEmpty() && params.multiRef) {
				error ("ERROR: The workflow was expecting user provided '.paths' files, but none were found in '${params.pathsDir}'.")
			}

			if (!foundPaths.isEmpty() && !params.multiRef) {
				println ("WARN: found reference '.paths' files in '${params.pathsDir}', but grave is not configured to use them. To do so use the '--multiRef' parameter and provide a multi-reference graph.")
			}

		// Import samplesheet

			// Initialise empty set for detecting duplicate repeat numbers
			def uniqueRepeats = new HashSet<String>()

			Channel
				.fromPath("${params.samplesheet}", checkIfExists: true)
				.splitCsv(header: true)
				.map { row ->

					// Populate metadata
					def meta = [
						id: row.id,
						repeat: row.repeat,
						type: row.type.toLowerCase(),
						merged: row.merged.toLowerCase()
					]

					// Check no duplicate "sample + repeat" combinations
					def key = "${meta.id}${meta.repeat}"
					if (!uniqueRepeats.add(key)) {
						error ("Error: found duplicate repeat numbers for sample '${meta.id}' in the samplesheet.")
					}

					// Check that merge information is true or false, convert to boolean
					if (!['true', 'false'].contains(meta.merged)) {
						error ("ERROR: Sample '${meta.id}' has an invalid 'merged' value: '${meta.merged}'. Please only supply 'true' or 'false' (case insensitive).")
					}
					meta.merged = meta.merged.toBoolean()

					// Check sample types are correctly stated
					if (!['ancient', 'modern'].contains(meta.type)) {
						error ("Error: for '${meta.id}_repeat_${meta.repeat}' found the phrase '${meta.type}' in the samplesheet 'type' column, accepts 'ancient' or 'modern' (case insensitive).")
					}

					// Initial checks passed, add FASTQ paths
					if (meta.merged) {
						if (row.fastq_1 && !row.fastq_2) {
							return [meta, [file(row.fastq_1)]]
						} else if (!row.fastq_1) {
							error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. No path to the merged FASTQ file is provided in column 'fastq_1'.")
						} else {
							error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. The 'merged' field is true, but a second FASTQ file was unexpectedly provided.")
						}
					} else if (!meta.merged) {
						if (row.fastq_1 && row.fastq_2) {
							return [meta, [file(row.fastq_1), file(row.fastq_2)]]
						} else {
							error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. In the samplesheet one or more FASTQ files appear to be missing.")
						}
					}
				}
				.set { ch_samplesheet }

		// Create types channel for correct index generation (modern, ancient, or both)

			ch_types = Channel.empty()

			ch_samplesheet
				.map { meta, fastqs ->
					return meta.type // Return all sample types
				}
				.unique() // Remove duplicates
				.collect() // Add uniques to list
				.map { uniqueTypes ->
					return uniqueTypes.size() == 1 ? uniqueTypes[0] : 'both' // If one type found, assign it to "ch_types". Else assign "both".
				}
				.set { ch_types }

		// Create graph channel

			Channel
				.fromPath("${params.graphDir}/*.gbz")
				.set { ch_gbz_graph }

	emit:

		// Emit channels to main workflow

			ch_samplesheet
			ch_types
			ch_gbz_graph

}
