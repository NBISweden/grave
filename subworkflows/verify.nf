/* 
----------------------------------------------------------------------------------------
Verify base dependencies & check for required inputs
----------------------------------------------------------------------------------------
*/

// Verification workflow execution

workflow VERIFY {

	// Nextflow version

	if (!nextflow.version.matches('>=22.03')) {
		error ("Oops! This workflow requires Nextflow version 22.03 or greater. You are running version $nextflow.version")
	}

	// Apptainer executable

	if (!"apptainer".execute().text.trim()) {
		error ("This workflow requires the Apptainer executable available in PATH.")
	}

	// Check for input samplesheet

	if (!file("./data/${params.samplesheet}").exists()) {
		error("Input file 'data/$params.samplesheet' was not found (please see docs).")
	}

	// Check directory structure

	if (!file("./data/reference").isDirectory()) {
		println("Pangenome directory 'data/reference' was not found. Creating it and exiting. Please add or link to reference files there (see docs).")
		file("data/reference").mkdirs()
		error("Created 'data/reference'. Exiting...")
	}

	// Check for reference files (different inputs depending on 'haplo' or 'filter' modes)

		// This section defines the expected reference file patterns
		def refPath = new File ("data/reference")
		def haplPattern = ~/.*\.hapl$/
		def gbzPattern = ~/.*\.gbz$/
		def distPattern = ~/.*\.dist$/
		def minPattern = ~/.*\.min$/
		def gbzFilteredPattern = ~/.*\.d.*\.gbz$/
		def distFilteredPattern = ~/.*\.d.*\.dist$/
		def minFilteredPattern = ~/.*\.d.*\.min$/
		def foundHapl = refPath.listFiles().findAll { it.isFile() && it.name =~ haplPattern }
		def foundGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzPattern }
		def foundDist = refPath.listFiles().findAll { it.isFile() && it.name =~ distPattern }
		def foundMin = refPath.listFiles().findAll { it.isFile() && it.name =~ minPattern }
		def foundFilteredGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzFilteredPattern }
		def foundFilteredDist = refPath.listFiles().findAll { it.isFile() && it.name =~ distFilteredPattern }
		def foundFilteredMin = refPath.listFiles().findAll { it.isFile() && it.name =~ minFilteredPattern }

		// In haplo mode, we need two files with only the reference basename (i.e. no file patterns matching filtered graphs)
		if ("$params.referenceMode" == "haplo") {
			// Haplotype file is not present in filter mode, so check for presence/absence and count
			if (foundHapl.isEmpty()) {
				error ("Reference mode is 'haplo' but no '.hapl' index found (please see docs). Exiting...")
			} else if (foundHapl.size() > 1) {
				error ("More than one '.hapl' file found in 'data/reference'.")
			// Check for gbz file
			} else if (foundGbz.isEmpty()) {
				error ("No '.gbz' file found (please see docs). Exiting...")
			} else if (foundGbz.size() > 1) {
				error ("More than one '.gbz' file found in 'data/reference'. For 'haplo' mode use the unfiltered .gbz graph.")
			} else if (!foundFilteredGbz.isEmpty()) {
				error ("The .gbz file found in 'data/reference' looks like a filtered graph. For 'haplo' mode use the unfiltered .gbz graph.")
			// Dist and min files suggest wrong inputs have been provided, so these will throw an error.
			} else if (!foundDist.isEmpty()) {
				error ("The '.dist' file in 'data/reference' is not required (please see docs). Exiting...")
			} else if (!foundMin.isEmpty()) {
				error ("The '.min' file in 'data/reference' is not required (please see docs). Exiting...")
			}
		// In filter mode, we need three files, all matching filtered patterns
		} else if ("$params.referenceMode" == "filter") {
			if (!foundHapl.isEmpty()) {
				error ("Reference mode is 'filter' but a '.hapl' index was found (please see docs). Exiting...")
			} else if (foundGbz.isEmpty()) {
				error ("No '.gbz' file found (please see docs). Exiting...")
			} else if (foundGbz.size() > 1) {
				error ("More than one '.gbz' file found in 'data/reference'. For 'filter' mode use the filtered .gbz graph.")
			} else if (foundFilteredGbz.isEmpty()) {
				error ("The .gbz file found in 'data/reference' does not look like a filtered graph. For 'filter' mode use the filtered .gbz graph.")
			} else if (foundDist.isEmpty()) {
				error ("No '.dist' file found (please see docs). Exiting...")
			} else if (foundDist.size() > 1) {
				error ("More than one '.dist' file found in 'data/reference'. For 'filter' mode use indexes for the filtered .gbz graph.")
			} else if (foundFilteredDist.isEmpty()) {
				error ("The .dist file found in 'data/reference' does not look like it was made for a filtered graph.")
			} else if (foundMin.isEmpty()) {
				error ("No '.min' file found (please see docs). Exiting...")
			} else if (foundMin.size() > 1) {
				error ("More than one '.min' file found in 'data/reference'. For 'filter' mode use indexes for the filtered .gbz graph.")
			} else if (foundFilteredMin.isEmpty()) {
				error ("The .min file found in 'data/reference' does not look like it was made for a filtered graph.")
			}
		// Prompt the user if there is a typo in the reference mode param
		} else {
			error ("Reference mode parameter '$params.referenceMode' not recognised, accepts 'haplo' or 'filter' (please see docs).")
		}
}
