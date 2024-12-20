/* 
----------------------------------------------------------------------------------------
Verify base dependencies & check required inputs
----------------------------------------------------------------------------------------
*/

// Verification workflow execution

workflow VERIFY {

	// Help message

		if (params.help) {
			println (" ")
			println ("grave: Graph Variant Explorer")
			println ("To run with all defaults: nextflow main.nf")
			println (" ")
			println ("Command line parameters [default option within square brackets]:")
			println (" ")
			println ("Graph input parameters:")
			println (" ")
			println ("--graphMode [${params.graphMode}] 					Use personal pangenomes (haplo), or filtered graphs (filter). See main docs or Minigraph-Cactus docs for more info.")
			println ("--multiRef [${params.multiRef}] 					Tell grave to use provided '.paths' files containing lists of reference sample paths (not required for graphs containing only one reference sample).")
			println (" ")
			println ("Turn on or off variant callers:")
			println (" ")
			println ("--graphCall [${params.graphCall}] 					Call variants from the graph, or skip (true/false).")
			println ("--vgMapCall [${params.vgMapCall}] 					Call graph variants in mapped samples with vg call (true/false).")
			println ("--deepVariant [${params.deepVariant}] 					Call variants in mapped samples with DeepVariant (true/false).")
			println ("--freeBayes [${params.freeBayes}] 					Call variants in mapped samples with FreeBayes (true/false).")
			println (" ")
			println ("Haplotype subsampling parameters:")
			println (" ")
			println ("--aDNAkmerHaplSubSam [${params.aDNAkmerHaplSubSam}] 				K value when K-mer profiling ancient DNA samples for haplotype subsampling.")
			println ("--aDNAwindowHaplSubSam [${params.aDNAwindowHaplSubSam}] 				Window size when constructing '.hapl' index for ancient DNA samples.")
			println ("--modernKmerHaplSubSam [${params.modernKmerHaplSubSam}] 				K value when K-mer profiling modern samples for haplotype subsampling.")
			println ("--modernWindowHaplSubSam [${params.modernWindowHaplSubSam}] 				Window size when constructing '.hapl' index for modern samples.")
			println (" ")
			println ("Minimizer construction parameters:")
			println (" ")
			println ("--aDNAkmerMinimizer [${params.aDNAkmerMinimizer}] 				K value when constructing minimizer indexes for ancient DNA samples.")
			println ("--aDNAwindowMinimizer [${params.aDNAwindowMinimizer}] 				Window size when constructing minimizer indexes for ancient DNA samples.")
			println ("--modernKmerMinimizer [${params.modernKmerMinimizer}] 				K value when constructing minimizer indexes for modern samples.")
			println ("--modernWindowMinimizer [${params.modernWindowMinimizer}] 				Window size when constructing minimizer indexes for modern samples.")
			println (" ")
			println ("FASTP parameters:")
			println (" ")
			println ("--dupCalcAccuracy [${params.dupCalcAccuracy}] 					Accuracy level to calculate duplication (1~6), higher level uses more memory (1G, 2G, 4G, 8G, 16G, 24G). 1 for no-dedup mode, 3 for dedup mode.")
            println ("--readDiscardLength [${params.readDiscardLength}] 				Reads shorter than INT will be discarded.")
			println (" ")
			println ("Mapping parameters:")
			println (" ")
			println ("--kffKmerMinimum [${params.kffKmerMinimum}] 					Minimum occurences of a K-mer to be counted during haplotype subsampling.")
			println ("--minimumScorePrimaryAlign [${params.minimumScorePrimaryAlign}] 			Minimum score to keep primary alignment during filtering.")
			println ("--minimumMapQFilter [${params.minimumMapQFilter}] 				Filter alignments with mapping quality < INT.")
			println (" ")
			println ("General variant calling parameters:")
			println (" ")
			println ("--maxNestLevel [${params.maxNestLevel}]					During VCF processing (for graph based calling & vg call), remove nested variants with nest level over INT. Does not affect raw VCF output.")
			println ("--maxRefLength [${params.maxRefLength}] 				During VCF processing (for graph based calling & vg call), remove variants over INT in length. Does not affect raw VCF output.")
			println ("--samplePloidy [${params.samplePloidy}] 					Sample ploidy.")
			println ("--minimumAlleleSupport [${params.minimumAlleleSupport}] 				Minimum allele support for a call.")
			println (" ")
			println ("vg call parameters:")
			println (" ")
			println ("--minimumSiteSupport [${params.minimumSiteSupport}] 				Minimum site support for a call.")
			println ("--baselineErrorSmallVariants [${params.baselineErrorSmallVariants}] 			Baseline error rates for Poisson model for small variants.")
			println ("--baselineErrorLargeVariants [${params.baselineErrorLargeVariants}] 			Baseline error rates for Poisson model for large variants.")
			println (" ")
			println ("DeepVariant parameters:")
			println (" ")
			println ("--deepVariantModelType [${params.deepVariantModelType}] 				WGS/WES/PACBIO/ONT_R104/HYBRID_PACBIO_ILLUMINA")
			println (" ")
			println ("FreeBayes parameters:")
			println (" ")
			println ("--maxComplexGap [${params.maxComplexGap}] 					Maximum distance between polymorphisms on the same read.")
			println ("--minFraction [${params.minFraction}] 					Require at least this fraction of observations supporting an alternate allele within a single individual in the in order to evaluate the position.")
			println (" ")
			println ("Help message:")
			println (" ")
			error ("--help 							Print this message.")
		}

	// Nextflow version

		if (!nextflow.version.matches('>=24.02.0')) {
			error ("ERROR: This workflow requires Nextflow version '24.02.0-edge' or later. You are running '${nextflow.version}'. Update with 'nextflow self-update'.")
		}

	// Apptainer executable

		if (!"apptainer".execute().text.trim()) {
			error ("ERROR: This workflow requires the Apptainer executable available in PATH.")
		}

	// Check for input samplesheet

		if (!file("./data/samplesheet/samplesheet.csv").exists()) {
			error ("ERROR: Input file 'data/samplesheet/samplesheet.csv' was not found (please see docs).")
		}

	// Check directory structure

		if (!file("./data/graph").isDirectory()) {
			println("ERROR: Pangenome directory 'data/graph' was not found. Creating it and exiting. Please add or link to the graph there (see docs).")
			file("data/graph").mkdirs()
			error ("Created 'data/graph'.")
		}

	// Warn about process settings

	// Graph call

		if (params.graphCall.toString().toLowerCase() in ["true", "false"]) {
			boolean graphCallEnabled = params.graphCall.toString().toLowerCase() == "true"
			if (!graphCallEnabled) {
				println ("USER NOTE: Variant calling directly from the graph is disabled.")
			}
		} else {
			error ("ERROR: Invalid value '${params.graphCall}' for '--graphCall' parameter. Please specify either 'true' or 'false' (case insensitive).")
		}

	// Vg map call

		if (params.vgMapCall.toString().toLowerCase() in ["true", "false"]) {
			boolean vgMapCallEnabled = params.vgMapCall.toString().toLowerCase() == "true"
			if (!vgMapCallEnabled) {
				println ("USER NOTE: Variant calling with vg call is disabled.")
			}
		} else {
			error ("ERROR: Invalid value '${params.vgMapCall}' for '--vgMapCall' parameter. Please specify either 'true' or 'false' (case insensitive).")
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

	// Compute snarls (only if both graph calling and vg call are disabled)

		if (params.graphCall.toString().toLowerCase() && params.vgMapCall.toString().toLowerCase() in ["true", "false"]) {
			boolean graphAndVgCallDisabled = params.graphCall.toString().toLowerCase() == "false" && params.vgMapCall.toString().toLowerCase() == "false"
			if (graphAndVgCallDisabled) {
				println ("USER NOTE: Since the graph and vg call variant callers are disabled, snarls will also not be computed.")
			}
		}

	// Check for reference paths

		if (!params.multiRef) {
			println ("USER NOTE: As no reference paths were provided, grave will assume a single reference sample is present in your graph.")
		}

	// Check for graph files (different inputs depending on 'haplo' or 'filter' modes)

		// Defines the expected graph file patterns
		def graphDir = new File ("data/graph")
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
				println ("USER NOTE: grave will not use the '.hapl' file you provided in 'data/graph', but you don't need to take action (see docs).")
			}

			if (foundGbz.isEmpty()) {
				error ("ERROR: No '.gbz' file found (please see docs).")
			}

			if (foundGbz.size() > 1) {
				error ("ERROR: More than one '.gbz' file found in 'data/graph'. For 'haplo' mode use the clipped unfiltered graph.")
			}

			if (!foundFilteredGbz.isEmpty()) {
				error ("ERROR: The '.gbz' file found in 'data/graph' looks like a filtered graph. For 'haplo' mode use the clipped unfiltered graph.")
			}

			// Dist and min files suggest wrong inputs have been provided, so these will throw an error.
			if (!foundDist.isEmpty()) {
				error ("ERROR: The '.dist' file in 'data/graph' is not required in haplo mode, please ensure you have run upstream processes correctly (see docs).")
			}

			if (!foundMin.isEmpty()) {
				error ("ERROR: The '.min' file in 'data/graph' is not required in haplo mode, please ensure you have run upstream processes correctly (see docs).")
			}

		// Filter mode uses the clipped filtered graph
		} else if ("$params.graphMode" == "filter") {

			if (!foundHapl.isEmpty()) {
				error ("ERROR: Graph mode is 'filter' but a '.hapl' index was found, please ensure you have run upstream processes correctly (see docs).")
			}

			if (foundGbz.isEmpty()) {
				error ("ERROR: No '.gbz' file found (please see docs).")
			}

			if (foundGbz.size() > 1) {
				error ("ERROR: More than one '.gbz' file found in 'data/graph'. For 'filter' mode use the clipped filtered graph.")
			}

			if (foundFilteredGbz.isEmpty()) {
				error ("ERROR: The .gbz file found in 'data/graph' does not look like a filtered graph. For 'filter' mode use the clipped filtered graph.")
			}

			if (!foundDist.isEmpty()) {
				println ("USER NOTE: grave will not use the '.dist' file you provided in 'data/graph', but you don't need to take action (see docs).")
			}

			if (!foundMin.isEmpty()) {
				println ("USER NOTE: grave will not use the '.min' file you provided in 'data/graph', but you don't need to take action (see docs).")
			}

		// Prompt the user if there is a typo in the graph mode param
		} else {
			error ("ERROR: Graph mode parameter '${params.graphMode}' not recognised, accepts 'haplo' or 'filter' (please see docs).")
		}

	// Check for files specifying reference paths

		def pathsDir = new File ("data/paths")
		def pathsPattern = ~/.*\.paths$/
		def foundPaths = pathsDir.listFiles().findAll { it.isFile() && it.name =~ pathsPattern }

		if (foundPaths.isEmpty() && params.multiRef) {
			error ("ERROR: The workflow was expecting user provided '.paths' files, but none were found in 'data/paths/*.paths'.")
		}

		if (!foundPaths.isEmpty() && !params.multiRef) {
			println ("WARN: found reference path files in 'data/paths/*.paths', but the workflow is not configured to use them; to do so provide: '--multiRef').")
		}

}
