/* 
----------------------------------------------------------------------------------------
Verify base dependencies & check for required inputs
----------------------------------------------------------------------------------------
*/

workflow VERIFY {

	// Nextflow version

	if (!nextflow.version.matches('>=22.03')) {
    	error "Oops! This workflow requires Nextflow version 22.03 or greater. You are running version $nextflow.version"
	}

	// Apptainer executable

	if (!"apptainer".execute().text.trim()) {
        error "The Apptainer executable is not in your PATH."
	}

	// Inputs

	if (!file("$params.input").exists()) {
		error("Input file '$params.input' was not found. Either add it to the data directory, or specify the samplesheet file using the --input command line argument.")
	}

}
