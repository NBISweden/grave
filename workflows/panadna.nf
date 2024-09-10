/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Import modules

include { FASTP } from '../modules/fastp.nf'
include { FASTQC } from '../modules/fastqc.nf'
include { MULTIQC } from '../modules/multiqc.nf'
include { REFSTATS } from '../modules/refstats.nf'
include { PANMAP } from '../modules/panmap.nf'

// Process samplesheet, output tuple channel "ch_samplesheet" with two elements: key-accessible metadata and FASTQ path list

def ch_samplesheet = Channel
	.fromPath("./data/${params.samplesheet}")
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

// Load pangenome reference files, allow for two upstream graph construction modes: "haplo" (current best practice) or "filter"
// Put into value channels using collect operator (not consumed by processes)

if ("$params.referenceMode" == "haplo") {
	ch_gbz_graph = Channel.fromPath("./data/reference/*.gbz")
	ch_hapl_index = Channel.fromPath("./data/reference/*.hapl")
	// The single index file fills the second tuple element
	ch_reference_inputs = ch_gbz_graph.combine(ch_hapl_index).collect()
} else if ("$params.referenceMode" == "filter") {
    ch_gbz_graph = Channel.fromPath("./data/reference/*.gbz")
    ch_dist_index = Channel.fromPath("./data/reference/*.dist")
    ch_min_index = Channel.fromPath("./data/reference/*.min")
	// Put both index files in the second tuple element
	ch_reference_inputs = ch_gbz_graph.combine(ch_dist_index.combine(ch_min_index)).collect()
		.map {element ->
			def ref = element[0]
			def dist = element[1]
			def min = element[2]
			return [ref: ref, indexes: [dist, min]]
		}
}

// Pangenome mapping workflow execution

workflow PANADNA {

	// Report reference file summary statistics
	REFSTATS (ch_gbz_graph)

	// Run quality filtering on input reads
	FASTP (ch_samplesheet)

	// Report read quality before and after filtering
	FASTQC (ch_samplesheet, FASTP.out.ch_fastp_reads)

	// Map reads to pangenome reference
	PANMAP(FASTP.out.ch_fastp_reads, ch_reference_inputs)

	// Collate quality reports
	MULTIQC(FASTP.out.ch_fastp_report.collect(), FASTQC.out.ch_fastqc_report.collect())

}
