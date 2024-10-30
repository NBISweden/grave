/* 
----------------------------------------------------------------------------------------
Verify base dependencies & check required inputs
----------------------------------------------------------------------------------------
*/

// Verification workflow execution

workflow VERIFY {

	// Nextflow version

	if (!nextflow.version.matches('>=22.03')) {
		error ("Oops! This workflow requires Nextflow version 22.03 or greater. You are running version ${nextflow.version}")
	}

	// Apptainer executable

	if (!"apptainer".execute().text.trim()) {
		error ("This workflow requires the Apptainer executable available in PATH.")
	}

	// Check for input samplesheet

	if (!file("./data/${params.samplesheet}").exists()) {
		error ("Input file 'data/${params.samplesheet}' was not found (please see docs).")
	}

	// Check directory structure

	if (!file("./data/reference").isDirectory()) {
		println("Pangenome directory 'data/reference' was not found. Creating it and exiting. Please add or link to reference files there (see docs).")
		file("data/reference").mkdirs()
		error ("Created 'data/reference'. Exiting...")
	}

	// Warn about optional process settings

	if (params.graphCall.toString().toLowerCase() in ["true", "false"]) {
		boolean graphCallEnabled = params.graphCall.toString().toLowerCase() == "true"
		if (!graphCallEnabled) {
			println ("USER NOTE: graph based variant calling is disabled.")
		}
	} else {
		error ("Invalid value '${params.graphCall}' for '--graphCall' parameter. Please specify either 'true' or 'false' (not case sensitive).")
	}

	// Check for reference files (different inputs depending on 'haplo' or 'filter' modes)

		// Defines the expected reference file patterns
		def refPath = new File ("data/reference")
		def haplPattern = ~/.*\.hapl$/
		def gbzPattern = ~/.*\.gbz$/
		def distPattern = ~/.*\.dist$/
		def minPattern = ~/.*\.min$/
		def gbzFilteredPattern = ~/.*\.d.*\.gbz$/
		def foundHapl = refPath.listFiles().findAll { it.isFile() && it.name =~ haplPattern }
		def foundGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzPattern }
		def foundDist = refPath.listFiles().findAll { it.isFile() && it.name =~ distPattern }
		def foundMin = refPath.listFiles().findAll { it.isFile() && it.name =~ minPattern }
		def foundFilteredGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzFilteredPattern }

		// Haplo mode uses the clipped unfiltered graph (i.e. no file pattern matching a filtered graph)
		if ("${params.referenceMode}" == "haplo") {

			if (!foundHapl.isEmpty()) {
				println ("For your information: pan-aDNA will not use the '.hapl' file you provided in 'data/reference', but you don't need to take action (see docs).")
			}

			if (foundGbz.isEmpty()) {
				error ("No '.gbz' file found (please see docs). Exiting...")
			}

			if (foundGbz.size() > 1) {
				error ("More than one '.gbz' file found in 'data/reference'. For 'haplo' mode use the clipped unfiltered graph.")
			}

			if (!foundFilteredGbz.isEmpty()) {
				error ("The '.gbz' file found in 'data/reference' looks like a filtered graph. For 'haplo' mode use the clipped unfiltered graph.")
			}

			// Dist and min files suggest wrong inputs have been provided, so these will throw an error.
			if (!foundDist.isEmpty()) {
				error ("The '.dist' file in 'data/reference' is not required in haplo mode, please ensure you have run upstream processes correctly (see docs). Exiting...")
			}

			if (!foundMin.isEmpty()) {
				error ("The '.min' file in 'data/reference' is not required in haplo mode, please ensure you have run upstream processes correctly (see docs). Exiting...")
			}

		// Filter mode uses the clipped filtered graph
		} else if ("$params.referenceMode" == "filter") {

			if (!foundHapl.isEmpty()) {
				error ("Reference mode is 'filter' but a '.hapl' index was found, please ensure you have run upstream processes correctly (see docs). Exiting...")
			}

			if (foundGbz.isEmpty()) {
				error ("No '.gbz' file found (please see docs). Exiting...")
			}

			if (foundGbz.size() > 1) {
				error ("More than one '.gbz' file found in 'data/reference'. For 'filter' mode use the clipped filtered graph.")
			}

			if (foundFilteredGbz.isEmpty()) {
				error ("The .gbz file found in 'data/reference' does not look like a filtered graph. For 'filter' mode use the clipped filtered graph.")
			}

			if (!foundDist.isEmpty()) {
				println ("For your information: pan-aDNA will not use the '.dist' file you provided in 'data/reference', but you don't need to take action (see docs).")
			}

			if (!foundMin.isEmpty()) {
				println ("For your information: pan-aDNA will not use the '.min' file you provided in 'data/reference', but you don't need to take action (see docs).")
			}

		// Prompt the user if there is a typo in the reference mode param
		} else {
			error ("Reference mode parameter '${params.referenceMode}' not recognised, accepts 'haplo' or 'filter' (please see docs).")
		}
}
