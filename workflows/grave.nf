/* 
----------------------------------------------------------------------------------------
Main workflow
----------------------------------------------------------------------------------------
*/

// Feature flags

	nextflow.preview.topic = true
	nextflow.preview.output = true

// Imports

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

// Main workflow

	// Optional input defined in main workflow script to avoid implicit channel creation if absent

	ch_ref_path_files = params.multiRef ? Channel.fromPath("${params.pathsDir}/*.paths") : []

	// Grave

	workflow GRAVE {

		take:

			ch_samplesheet
			ch_types
			ch_gbz_graph

		main:

			// Create appropriate graph indexes

				if ("${params.graphMode}" == "haplo") {
					MAKEHAPL(ch_gbz_graph, ch_types)
					ch_indexed_graph = ch_gbz_graph.combine(MAKEHAPL.out.ch_hapl_indexes).collect()
						.map {element ->
							def ref = element[0]
							def indexes = element.size() == 3 ? [element[1], element[2]] : element[1] // Array == 3 if ref + two indexes, else == 2 for ref + index
							return [ref: ref, indexes: indexes]
						}
				} else if ("${params.graphMode}" == "filter") {
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

				FASTQMERGEDEDUP(
					FASTP.out.ch_fastp_reads
						.map{ meta, fastqs -> [meta.subMap('id', 'type', 'merged'), fastqs] } // Create metadata subset to group on
						.groupTuple() // Group by sample
						.map{ meta, fastqs -> [meta, fastqs.flatten()] } // Flatten any nested lists
				)

			// Report skipped single library samples, as they were already deduplicated

				FASTQMERGEDEDUP.out.ch_skipped_samples
					.collectFile(name: 'skipped-samples.txt', storeDir: "${projectDir}/results/quality_reports/fastp-sample-level")

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
					.map { it.join('\n') }
					.collectFile(name: 'package_versions.txt', newLine: true)
					.set { ch_versions }

		emit:

			// Emit channels for publication

				ch_versions = ch_versions

	}
