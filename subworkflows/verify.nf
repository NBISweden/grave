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
			println ("pan-aDNA Nextflow workflow")
			println ("To run with all defaults: nextflow main.nf")
			println (" ")
			println ("Command line parameters [default option]:")
			println (" ")
			println ("--graphMode [haplo]/filter 					[Use personal pangenomes], or filtered graphs.")
			println ("--refPaths true/[false] 					Provide '.paths' files containing lists of reference sample paths, or [use all reference sample paths (i.e. for graphs with only one reference sample)]")
			println ("--graphCall [true]/false 					[Call variants from the graph], or skip.")
			println ("--deepvariantModelType [WGS]/WES/PACBIO/ONT_R104/HYBRID_PACBIO_ILLUMINA")

			error ("--help 								Print this message.")
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

	// Compute snarls (only if both graph calling and vg call are disabled)

		if (params.graphCall.toString().toLowerCase() && params.vgMapCall.toString().toLowerCase() in ["true", "false"]) {
			boolean graphAndVgCallDisabled = params.graphCall.toString().toLowerCase() == "false" && params.vgMapCall.toString().toLowerCase() == "false"
			if (graphAndVgCallDisabled) {
				println ("USER NOTE: Since the graph and vg call variant callers are disabled, snarls will also not be computed.")
			}
		}

	// Check for reference paths

		if (!params.refPaths) {
			println ("USER NOTE: As no reference paths were provided, pan-aDNA will assume a single reference sample is present in your graph.")
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
				println ("USER NOTE: pan-aDNA will not use the '.hapl' file you provided in 'data/graph', but you don't need to take action (see docs).")
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
				println ("USER NOTE: pan-aDNA will not use the '.dist' file you provided in 'data/graph', but you don't need to take action (see docs).")
			}

			if (!foundMin.isEmpty()) {
				println ("USER NOTE: pan-aDNA will not use the '.min' file you provided in 'data/graph', but you don't need to take action (see docs).")
			}

		// Prompt the user if there is a typo in the graph mode param
		} else {
			error ("ERROR: Graph mode parameter '${params.graphMode}' not recognised, accepts 'haplo' or 'filter' (please see docs).")
		}

	// Check for files specifying reference paths

		def pathsDir = new File ("data/paths")
		def pathsPattern = ~/.*\.paths$/
		def foundPaths = pathsDir.listFiles().findAll { it.isFile() && it.name =~ pathsPattern }

		if (foundPaths.isEmpty() && params.refPaths) {
			error ("ERROR: The workflow was expecting user provided '.paths' files, but none were found in 'data/paths/*.paths'.")
		}

		if (!foundPaths.isEmpty() && !params.refPaths) {
			println ("WARN: found reference path files in 'data/paths/*.paths', but the workflow is not configured to use them; to do so set '--refPaths true').")
		}

}
