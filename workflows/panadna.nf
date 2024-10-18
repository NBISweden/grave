/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Import modules

include { MAKEHAPL } from '../modules/make-hapl.nf'
include { MAKEFILTER } from '../modules/make-filter.nf'
include { PROCESSREF } from '../modules/process-ref.nf'
include { FASTP } from '../modules/fastp.nf'
include { FASTQC } from '../modules/fastqc.nf'
include { PANMAP } from '../modules/panmap.nf'
include { PROFILEPMD } from '../modules/profile-pmd.nf'
include { MULTIQC } from '../modules/multiqc.nf'

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

// Pangenome mapping workflow execution

workflow PANADNA {

	// Load pangenome graph. Allow for two upstream construction modes: "haplo" (current best practice) and "filter"

	if ("$params.referenceMode" == "haplo") {
		ch_gbz_graph = Channel.fromPath("./data/reference/*.gbz")
		// Remake hapl indexes
		MAKEHAPL (ch_gbz_graph)
		ch_reference_inputs = ch_gbz_graph.combine(MAKEHAPL.out.ch_hapl_indexes).collect()
			.map {element ->
				def ref = element[0]
				def adna_hapl = element[1]
				def modern_hapl = element[2]
				return [ref: ref, indexes: [adna_hapl, modern_hapl]]
			}
	} else if ("$params.referenceMode" == "filter") {
		ch_gbz_graph = Channel.fromPath("./data/reference/*.gbz")
		// Remake filter indexes
		MAKEFILTER (ch_gbz_graph)
		ch_reference_inputs = ch_gbz_graph.combine(MAKEFILTER.out.ch_filter_indexes).collect()
			.map {element ->
				def ref = element[0]
				def dist = element[1]
				def adna_min = element[2]
				def modern_min = element[3]
				return [ref: ref, indexes: [dist, adna_min, modern_min]]
			}
	}

	// Report reference file summary statistics & pull reference path for mapdamage
	PROCESSREF (ch_gbz_graph)

	// Run quality filtering on input reads
	FASTP (ch_samplesheet)

	// Report read quality before and after filtering
	FASTQC (ch_samplesheet, FASTP.out.ch_fastp_reads)

	// Map reads to pangenome reference
	PANMAP (FASTP.out.ch_fastp_reads, ch_reference_inputs)

	// Post-mortem damage assessment of reads
	PROFILEPMD (ch_gbz_graph.collect(), PROCESSREF.out.ch_reference_fasta.collect(), PANMAP.out.ch_mapped_gam)

	// Collate quality reports
	MULTIQC (FASTP.out.ch_fastp_report.collect(), FASTQC.out.ch_fastqc_report.collect())

}
