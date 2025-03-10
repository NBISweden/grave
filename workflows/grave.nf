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
	include { FASTQC as QCRAW; FASTQC as QCFASTP } from '../modules/fastqc.nf'
	include { FASTQMERGEDEDUP } from '../modules/fastq-merge-dedup.nf'
	include { PANMAP } from '../modules/panmap.nf'
	include { VGSURJECT } from '../modules/vg-surject.nf'
	include { BAMDEDUP } from '../modules/bam-dedup.nf'
	include { PROFILEPMD } from '../modules/profile-pmd.nf'
	include { VGGRAPHCALL } from '../modules/vg-graph-call.nf'
	include { VGMAPCALL } from '../modules/vg-map-call.nf'
	include { FREEBAYES } from '../modules/freebayes.nf'
	include { DEEPVARIANT } from '../modules/deepvariant.nf'
	include { DVPROCESSVCF } from '../modules/process-dv-vcf.nf'

// Main workflow

	// Optional input defined in main workflow script

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
					ch_gbz_graph.combine(MAKEHAPL.out.ch_hapl_indexes).collect()
						.map {element ->
							def ref = element[0]
							def indexes = element.size() == 3 ? [element[1], element[2]] : element[1] // Array == 3 if ref + two indexes, else == 2 for ref + index
							return [ref: ref, indexes: indexes]
						}
						.set { ch_indexed_graph }
				} else if ("${params.graphMode}" == "filter") {
					MAKEFILTER(ch_gbz_graph, ch_types)
					ch_gbz_graph.combine(MAKEFILTER.out.ch_filter_indexes).collect()
						.map {element ->
							def ref = element[0]
							def indexes = element.size() == 4 ? [element[1], element[2], element[3]] : [element[1], element[2]] // Array == 4 if ref + three indexes, else == 3 for ref + two indexes
							return [ref: ref, indexes: indexes]
						}
						.set { ch_indexed_graph }
				}

			// Report graph summary statistics & pull linear reference FASTAs

				PROCESSGRAPH(ch_gbz_graph, ch_ref_path_files.collect())

			// Compute graph snarls for variant calling/genotyping tasks

				COMPUTESNARLS(ch_gbz_graph)

			// Run quality filtering on input reads

				FASTP(ch_samplesheet)

			// Run FASTQC on raw reads

				QCRAW(ch_samplesheet)

			// Run FASTQC on filtered reads

				QCFASTP(FASTP.out.ch_fastp_reads)

			// Merge and deduplicate FASTQs per sample

				FASTQMERGEDEDUP(
					FASTP.out.ch_fastp_reads
						.map{ meta, fastqs -> [meta.subMap('id', 'type', 'merged'), fastqs] } // Create metadata subset to group on
						.groupTuple() // Group by sample
						.map{ meta, fastqs -> [meta, fastqs.flatten()] } // Flatten any nested lists
				)

			// Map reads to pangenome graph

				PANMAP(FASTQMERGEDEDUP.out.ch_sample_fastqs, ch_indexed_graph)

			// Surject mapped reads to reference paths

				VGSURJECT(ch_gbz_graph.collect(), ch_ref_path_files.collect(), PANMAP.out.ch_mapped_gam)

			// Secondary deduplication on surjected BAMs per sample

				BAMDEDUP(ch_ref_path_files.collect(), VGSURJECT.out.ch_surjected_bams)

			// Post-mortem damage assessment of reads

				PROFILEPMD(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_indexed_bams)

			// Graph based variant calling

				VGGRAPHCALL(ch_gbz_graph, COMPUTESNARLS.out.ch_snarls, ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas)

			// Mapping based variant calling

				VGMAPCALL(ch_gbz_graph.collect(), COMPUTESNARLS.out.ch_snarls.collect(), ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), PANMAP.out.ch_mapped_gam)

				DEEPVARIANT(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_indexed_bams)

				DVPROCESSVCF(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), DEEPVARIANT.out.ch_raw_deepvariant_vcf)

				FREEBAYES(ch_ref_path_files.collect(), PROCESSGRAPH.out.ch_reference_fastas.collect(), BAMDEDUP.out.ch_sample_dedup_indexed_bams)

			// Report skipped single library samples, as they were already deduplicated

				FASTQMERGEDEDUP.out.ch_skipped_samples
					.collectFile(name: 'skipped-samples.txt')
					.set { ch_skipped_samples }

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

				ch_graph_stats = PROCESSGRAPH.out.ch_graph_stats
				ch_library_fastp_report = FASTP.out.ch_library_fastp_report
				ch_sample_fastp_report = FASTQMERGEDEDUP.out.ch_sample_fastp_report
				ch_fastqc_raw = QCRAW.out.ch_fastqc
				ch_fastqc_fastp = QCFASTP.out.ch_fastqc
				ch_alignment_stats = PANMAP.out.ch_alignment_stats
				ch_mapped_gam = PANMAP.out.ch_mapped_gam
				ch_raw_gam = PANMAP.out.ch_raw_gam
				ch_sample_dedup_bams = BAMDEDUP.out.ch_sample_dedup_bams
				ch_pmd_profiles = PROFILEPMD.out.ch_pmd_profiles
				ch_vg_graph_call_filtered_vcf = VGGRAPHCALL.out.ch_vg_graph_call_filtered_vcf
				ch_vg_graph_call_raw_vcf = VGGRAPHCALL.out.ch_vg_graph_call_raw_vcf
				ch_vg_map_call_filtered_vcf = VGMAPCALL.out.ch_vg_map_call_filtered_vcf
				ch_vg_map_call_raw_vcf = VGMAPCALL.out.ch_vg_map_call_raw_vcf
				ch_freebayes_norm_vcf = FREEBAYES.out.ch_freebayes_norm_vcf
				ch_freebayes_raw_vcf = FREEBAYES.out.ch_freebayes_raw_vcf
				ch_deepvariant_html = DEEPVARIANT.out.ch_deepvariant_html
				ch_deepvariant_norm_vcf = DVPROCESSVCF.out.ch_deepvariant_norm_vcf
				ch_deepvariant_raw_vcf = DVPROCESSVCF.out.ch_deepvariant_raw_vcf
				ch_skipped_samples = ch_skipped_samples
				ch_versions = ch_versions

	}
