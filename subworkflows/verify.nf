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

	// Check for reference files (different inputs depending on 'haplo' or 'filter' modes)
	// Mode dependent: expected file naming is checked and user prompted to give only required files

	if (!file("./data/reference").isDirectory()) {
		println("Pangenome directory 'data/reference' was not found. Creating it and exiting. Please add or link to reference files there (see docs).")
		file("data/reference").mkdirs()
		error("Created 'data/reference'. Exiting...")
	} else if ("$params.referenceMode" == "haplo") {
		def refPath = new File ("data/reference")
		def haplPattern = ~/.*\.hapl$/
		def gbzPattern = ~/.*\.gbz$/
		def foundHapl = refPath.listFiles().findAll { it.isFile() && it.name =~ haplPattern }
		def foundGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzPattern }
		if (foundHapl.isEmpty()) {
			error("Reference mode is 'haplo' but no '.hapl' index found (please see docs). Exiting...")
		} else if (foundGbz.isEmpty()) {
			error("Reference mode is 'haplo' but no '.gbz' file found (please see docs). Exiting...")
		} else if (foundGbz.size() > 1) {
			error("More than one '.gbz' file found in 'data/reference'. For 'haplo' mode use the unfiltered .gbz graph.")
		} else {
			def gbzFilteredPattern = ~/.*\.d.*\.gbz$/
			def foundFilteredGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzFilteredPattern }
			if (!foundFilteredGbz.isEmpty()) {
				error ("The .gbz file found in 'data/reference' looks like a filtered graph. For 'haplo' mode use the unfiltered .gbz graph.")
			}
		}
	} else if ("$params.referenceMode" == "filter") {
		def refPath = new File ("data/reference")
		def distPattern = ~/.*\.d.*\.dist$/
		def minPattern = ~/.*\.d.*\.min$/
		def gbzPattern = ~/.*\.gbz$/
		def foundDist = refPath.listFiles().findAll { it.isFile() && it.name =~ distPattern }
		def foundMin = refPath.listFiles().findAll { it.isFile() && it.name =~ minPattern }
		def foundGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzPattern }
		if (foundDist.isEmpty()) {
			error ("Reference mode is 'filter' but no filtered '.dist' index found (please see docs). Exiting...")
		} else if (foundMin.isEmpty()) {
			error ("Reference mode is 'filter' but no filtered '.min' index found (please see docs). Exiting...")
		} else if (foundGbz.isEmpty()) {
			error ("Reference mode is 'filter' but no '.gbz' file found (please see docs). Exiting...")
		} else if (foundGbz.size() > 1) {
			error ("More than one '.gbz' file found in 'data/reference'. For 'filter' mode use the filtered .gbz graph.")
		} else {
			gbzFilteredPattern = ~/.*\.d.*\.gbz$/
			def foundFilteredGbz = refPath.listFiles().findAll { it.isFile() && it.name =~ gbzFilteredPattern }
			if (foundFilteredGbz.isEmpty()) {
				error ("The .gbz file found in 'data/reference' does not look like a filtered graph. For 'filter' mode use the filtered .gbz graph.")
			}
		}
	} else {
		error ("Reference mode parameter '$params.referenceMode' not recognised, accepts 'haplo' or 'filter' (please see docs).")
	}
}
