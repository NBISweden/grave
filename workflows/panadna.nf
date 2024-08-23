/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Import modules

include { FASTQC } from '../modules/fastqc.nf'
include { FASTP } from '../modules/fastp.nf'


// Process samplesheet, output sample metadata and FASTQ paths in channel "ch_samplesheet"

def ch_samplesheet = Channel
	.fromPath(params.input)
	.splitCsv(header: true)
	.map { row ->
		// Initialise metadata list to travel with the files
		meta = [id: row.id, repeat: row.repeat]
		// Return metadata and file lists as a tuple, convert filestrings to paths
		if (row.fastq_2) {
			return [meta + [paired_end:true], [file(row.fastq_1), file(row.fastq_2)]]
		} else {
			return [meta + [paired_end:false], [file(row.fastq_1)]]
		}
	}

	// Workflow execution

workflow PANADNA { 

	//INDEXREF(    FIXME: reference    )
	FASTQC (ch_samplesheet)
	//FASTP (ch_samplesheet)

}
