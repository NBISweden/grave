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
	include { FASTQMERGEDEDUP } from '../modules/fastq-merge-dedup.nf'
	include { PANMAP } from '../modules/panmap.nf'
	include { VGSURJECT } from '../modules/vg-surject.nf'
	include { BAMDEDUP } from '../modules/bam-dedup.nf'
	include { PROFILEPMD } from '../modules/profile-pmd.nf'
	include { VGGRAPHCALL } from '../modules/vg-graph-call.nf'
	include { VGMAPCALL } from '../modules/vg-map-call.nf'
	include { DEEPVARIANT } from '../modules/deepvariant.nf'
	include { DVPROCESSVCF } from '../modules/process-dv-vcf.nf'
	include { FREEBAYES } from '../modules/freebayes.nf'

// Process samplesheet, check structure, output tuple "ch_samplesheet" with two elements: key-accessible metadata and FASTQ path list

	// Initialise empty set for detecting duplicate repeat numbers
	def uniqueRepeats = new HashSet<String>()

	// Load samplesheet
	def ch_samplesheet = Channel
		.fromPath("${params.samplesheet}")
		.splitCsv(header: true)
		.map { row ->

			// Populate metadata
			def meta = [
				id: row.id,
				repeat: row.repeat,
				type: row.type.toLowerCase(),
				merged: row.merged.toLowerCase()
			]

			// Check no duplicate "sample + repeat" combinations
			def key = "${meta.id}${meta.repeat}"
			if (!uniqueRepeats.add(key)) {
				error ("Error: found duplicate repeat numbers for sample '${meta.id}' in the samplesheet.")
			}

			// Check that merge information is true or false, convert to boolean
			if (!['true', 'false'].contains(meta.merged)) {
				error ("ERROR: Sample '${meta.id}' has an invalid 'merged' value: '${meta.merged}'. Please only supply 'true' or 'false' (case insensitive).")
			}
			meta.merged = meta.merged.toBoolean()

			// Check sample types are correctly stated
			if (!['ancient', 'modern'].contains(meta.type)) {
				error ("Error: for '${meta.id}_repeat_${meta.repeat}' found the phrase '${meta.type}' in the samplesheet 'type' column, accepts 'ancient' or 'modern' (case insensitive).")
			}

			// Initial checks passed, add FASTQ paths
			if (meta.merged) {
				if (row.fastq_1 && !row.fastq_2) {
					return [meta, [file(row.fastq_1)]]
				} else if (!row.fastq_1) {
					error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. No path to the merged FASTQ file is provided in column 'fastq_1'.")
				} else {
					error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. The 'merged' field is true, but a second FASTQ file was unexpectedly provided.")
				}
			} else if (!meta.merged) {
				if (row.fastq_1 && row.fastq_2) {
					return [meta, [file(row.fastq_1), file(row.fastq_2)]]
				} else {
					error ("Error caused by sample: '${meta.id}_repeat_${meta.repeat}'. In the samplesheet one or more FASTQ files appear to be missing.")
				}
			}
		}

// Determine whether to create modern or ancient indexes (or both), depending on sample input

	// Initialise channel to summarise discovered sample types
	ch_types = Channel.empty()

	// Collect sample types from samplesheet
	ch_samplesheet
		.map { meta, fastqs ->
			return meta.type // Return all sample types
		}
		.unique() // Remove duplicates
		.collect() // Add uniques to list
		.map { uniqueTypes ->
			return uniqueTypes.size() == 1 ? uniqueTypes[0] : 'both' // If one type found, assign it to "ch_types". Else assign "both".
		}
		.set { ch_types }

// Process reference path files as an optional input

	def ch_ref_path_files = params.multiRef ? Channel.fromPath("${params.pathsDir}/*.paths") : []

// Pangenome mapping & genotyping workflow execution

	workflow GRAVE {

		// Load pangenome graph. Allow for two upstream construction modes: "haplo" (current best practice) and "filter"
		if ("$params.graphMode" == "haplo") {
			ch_gbz_graph = Channel.fromPath("${params.graphDir}/*.gbz")
			// Remake hapl indexes
			MAKEHAPL(ch_gbz_graph, ch_types)
			ch_indexed_graph = ch_gbz_graph.combine(MAKEHAPL.out.ch_hapl_indexes).collect()
				.map {element ->
					def ref = element[0]
					def indexes = element.size() == 3 ? [element[1], element[2]] : element[1] // Array == 3 if ref + two indexes, else == 2 for ref + index
					return [ref: ref, indexes: indexes]
				}
		} else if ("$params.graphMode" == "filter") {
			ch_gbz_graph = Channel.fromPath("${params.graphDir}/*.gbz")
			// Remake filter indexes
			MAKEFILTER(ch_gbz_graph, ch_types)
			ch_indexed_graph = ch_gbz_graph.combine(MAKEFILTER.out.ch_filter_indexes).collect()
				.map {element ->
					def ref = element[0]
					def indexes = element.size() == 4 ? [element[1], element[2], element[3]] : [element[1], element[2]] // Array == 4 if ref + three indexes, else == 3 for ref + two indexes
					return [ref: ref, indexes: indexes]
				}
		}

		// Report graph summary statistics & pull linear reference FASTAs

			PROCESSGRAPH(ch_gbz_graph, ch_ref_path_files.collect())

		// Compute graph snarls for variant calling/genotyping tasks

			COMPUTESNARLS(ch_gbz_graph)

		// Run quality filtering on input reads

			FASTP(ch_samplesheet)

		// Merge raw and processed read channels for FASTQC, report read quality before and after filtering

			ch_fastqc_input = ch_samplesheet.join(FASTP.out.ch_fastp_reads, by: [0]) // Join on matching metadata

			FASTQC(ch_fastqc_input)

		// Merge and deduplicate FASTQs per sample

			FASTQMERGEDEDUP(FASTP.out.ch_fastp_reads
								.map{ meta, fastqs -> [meta.subMap('id', 'type', 'merged'), fastqs] } // Create metadata subset to group on
								.groupTuple() // Group by sample
								.map{ meta, fastqs -> [meta, fastqs.flatten()] } // Flatten any nested lists
			)

		// Report skipped single library samples, as they were already deduplicated

			FASTQMERGEDEDUP.out.ch_skipped_samples | collectFile(name: 'skipped-samples.txt', storeDir: "${projectDir}/output/quality_reports/fastp-sample-level")

		// Map reads to pangenome graph

			PANMAP(FASTQMERGEDEDUP.out.ch_sample_fastqs, ch_indexed_graph)

		// Surject mapped reads to reference paths

			VGSURJECT(ch_gbz_graph.collect(), ch_ref_path_files.collect(), PANMAP.out.ch_mapped_gam)

		// Secondary deduplication on surjected BAMs per sample

			BAMDEDUP(ch_ref_path_files.collect(), VGSURJECT.out.ch_surjected_bams)

		// Post-mortem damage assessment of reads

			PROFILEPMD(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_bams)

		// Graph based variant calling

			VGGRAPHCALL(ch_gbz_graph, COMPUTESNARLS.out.ch_snarls, ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas)

		// Mapping based variant calling

			VGMAPCALL(ch_gbz_graph.collect(), COMPUTESNARLS.out.ch_snarls.collect(), ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), PANMAP.out.ch_mapped_gam)

			DEEPVARIANT(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_bams)

			DVPROCESSVCF(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), DEEPVARIANT.out.ch_raw_deepvariant_vcf)

			FREEBAYES(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_bams)

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
