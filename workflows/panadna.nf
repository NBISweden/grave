/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Import modules

include { FASTP } from '../modules/fastp.nf'
include { FASTQC } from '../modules/fastqc.nf'


// Process samplesheet, output tuple channel "ch_samplesheet" with two elements: key-accessible metadata and FASTQ path list

def ch_samplesheet = Channel
	.fromPath(params.input)
	.splitCsv(header: true)
	.map { row ->
		// Initialise metadata list to travel with the files
		meta = [id: row.id, type: row.type, repeat: row.repeat]
		// Return metadata and file lists as a tuple, convert filestrings to paths
		if (row.fastq_2) {
			return [meta + [paired_end:true], [file(row.fastq_1), file(row.fastq_2)]]
		} else {
			error ("Error caused by sample: '$meta.id'. In the samplesheet it does not appear to be paired-end...")
		}
	}

// Workflow execution

workflow PANADNA { 

	//INDEXREF(    FIXME: reference    )
	FASTP (ch_samplesheet)
	//FASTQC (ch_samplesheet, ch_fastp_out)

}
