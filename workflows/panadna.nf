/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Import modules

include { FASTP } from '../modules/fastp.nf'
include { FASTQC } from '../modules/fastqc.nf'
include { MULTIQC } from '../modules/multiqc.nf'

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

	//REFSTATS (collect reference stats)

	FASTP (ch_samplesheet)

	FASTQC (ch_samplesheet, FASTP.out.ch_fastp_reads)

	MULTIQC(FASTP.out.ch_fastp_report.collect(), FASTQC.out.ch_fastqc_report.collect())

	//PANMAP(index ref if not done & map)

}
