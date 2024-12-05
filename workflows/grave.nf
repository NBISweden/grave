/* 
----------------------------------------------------------------------------------------
Main workflow definition
----------------------------------------------------------------------------------------
*/

// Feature flags

	nextflow.preview.topic = true

// Import modules

	include { MAKEHAPL } from '../modules/make-hapl.nf'
	include { MAKEFILTER } from '../modules/make-filter.nf'
	include { PROCESSGRAPH } from '../modules/process-graph.nf'
	include { COMPUTESNARLS } from '../modules/compute-snarls.nf'
	include { FASTP } from '../modules/fastp.nf'
	include { FASTQC } from '../modules/fastqc.nf'
	include { PANMAP } from '../modules/panmap.nf'
	include { VGSURJECT } from '../modules/vg-surject.nf'
	include { PROFILEPMD } from '../modules/profile-pmd.nf'
	include { VGGRAPHCALL } from '../modules/vg-graph-call.nf'
	include { VGMAPCALL } from '../modules/vg-map-call.nf'
	include { DEEPVARIANT } from '../modules/deepvariant.nf'
	include { DVPROCESSVCF } from '../modules/process-dv-vcf.nf'
	//include { MULTIQC } from '../modules/multiqc.nf'

// Process samplesheet, output tuple channel "ch_samplesheet" with two elements: key-accessible metadata and FASTQ path list

	def ch_samplesheet = Channel
		.fromPath("./data/samplesheet/samplesheet.csv")
		.splitCsv(header: true)
		.map { row ->
			// Initialise metadata list to travel with the files
			meta = [id: row.id, type: row.type, repeat: row.repeat]
			// Return metadata and file lists as a tuple, convert filestrings to paths
			if (row.fastq_2) {
				return [meta + [paired_end:true], [file(row.fastq_1), file(row.fastq_2)]]
			} else {
				error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. In the samplesheet it does not appear to be paired-end...")
			}
		}

// Process reference path files as an optional input

	def ch_ref_path_files = params.refPaths ? Channel.fromPath("./data/paths/*.paths") : []

// Pangenome mapping & genotyping workflow execution

	workflow GRAVE {

		// Load pangenome graph. Allow for two upstream construction modes: "haplo" (current best practice) and "filter"
		if ("$params.graphMode" == "haplo") {
			ch_gbz_graph = Channel.fromPath("./data/graph/*.gbz")
			// Remake hapl indexes
			MAKEHAPL (ch_gbz_graph)
			ch_indexed_graph = ch_gbz_graph.combine(MAKEHAPL.out.ch_hapl_indexes).collect()
				.map {element ->
					def ref = element[0]
					def adna_hapl = element[1]
					def modern_hapl = element[2]
					return [ref: ref, indexes: [adna_hapl, modern_hapl]]
				}
		} else if ("$params.graphMode" == "filter") {
			ch_gbz_graph = Channel.fromPath("./data/graph/*.gbz")
			// Remake filter indexes
			MAKEFILTER (ch_gbz_graph)
			ch_indexed_graph = ch_gbz_graph.combine(MAKEFILTER.out.ch_filter_indexes).collect()
				.map {element ->
					def ref = element[0]
					def dist = element[1]
					def adna_min = element[2]
					def modern_min = element[3]
					return [ref: ref, indexes: [dist, adna_min, modern_min]]
				}
		}

		// Report graph summary statistics & pull FASTAs for mapdamage

			PROCESSGRAPH (ch_gbz_graph, ch_ref_path_files.collect())

		// Compute graph snarls for variant calling/genotyping tasks (separate from PROCESSGRAPH to allow multithreading)

			COMPUTESNARLS (ch_gbz_graph)

		// Run quality filtering on input reads

			FASTP (ch_samplesheet)

		// Report read quality before and after filtering

			FASTQC (ch_samplesheet, FASTP.out.ch_fastp_reads)

		// Map reads to pangenome graph

			PANMAP (FASTP.out.ch_fastp_reads, ch_indexed_graph)

		// Surject mapped reads to reference paths

			VGSURJECT (ch_gbz_graph.collect(), ch_ref_path_files.collect(), PANMAP.out.ch_mapped_gam)

		// Post-mortem damage assessment of reads

			PROFILEPMD (PROCESSGRAPH.out.ch_reference_fastas.collect(), VGSURJECT.out.ch_surjected_bams)

		// Graph based variant calling

			VGGRAPHCALL (ch_gbz_graph, COMPUTESNARLS.out.ch_snarls, ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas)

		// Mapping based variant calling

			VGMAPCALL (ch_gbz_graph.collect(), COMPUTESNARLS.out.ch_snarls.collect(), ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), PANMAP.out.ch_mapped_gam)

			DEEPVARIANT(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), VGSURJECT.out.ch_surjected_bams)

			//FREEBAYES()

			DVPROCESSVCF(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), DEEPVARIANT.out.ch_raw_deepvariant_vcf)

		// Collate quality reports

			//MULTIQC (FASTP.out.ch_fastp_report.collect(), FASTQC.out.ch_fastqc_report.collect())

		// Report package versions

			Channel.topic('versions')
				.map { process, tool, version ->
					return [process: process, tool: tool, version: version]
				}
				.unique()
				.collect()
				.map { it.join('\n') } // Back to a single string
				.collectFile(name: 'package_versions.txt', newLine: true, storeDir: 'output/package_versions')

	}
