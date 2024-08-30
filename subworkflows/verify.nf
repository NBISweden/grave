/* 
----------------------------------------------------------------------------------------
Verify base dependencies & check for required inputs
----------------------------------------------------------------------------------------
*/

// Import modules

include { MAKECONTAINER } from '../modules/makecontainer.nf'

// Load container definition file as a channel

def ch_cactus_definition = Channel.fromPath(params.cactusDefinition)

// Workflow execution

workflow VERIFY {

	// Nextflow version

	if (!nextflow.version.matches('>=22.03')) {
    	error "Oops! This workflow requires Nextflow version 22.03 or greater. You are running version $nextflow.version"
	}

	// Apptainer executable

	if (!"apptainer".execute().text.trim()) {
        error "This workflow requires the Apptainer executable to be available in your PATH."
	}

	// Check for Cactus container, build if needed

	if (!file("$params.containerDir").isDirectory()) {
		println("Container directory '$params.containerDir' does not exist. Creating directory & building cactus container...")
			file(params.containerDir).mkdirs()
			MAKECONTAINER(ch_cactus_definition)
			println("Cactus container built.")
	} else {
		println("Container directory '$params.containerDir' exists, checking for cactus container...")
		if (!file("$params.containerDir/cactus.sif").exists()) {
			println("Cactus container not found in '$params.containerDir', building it...")
			MAKECONTAINER(ch_cactus_definition)
			println("Cactus container built.")
		} else {
			println("Cactus container found in '$params.containerDir', proceeding.")
		}
	}

	// Input files

	if (!file("$params.input").exists()) {
		error("Input file '$params.input' was not found. Either add it to the data directory, or specify the samplesheet file using the --input command line argument. See the README.md for formatting instructions.")
	}

}
