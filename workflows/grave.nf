/* 
----------------------------------------------------------------------------------------
Main workflow
----------------------------------------------------------------------------------------
*/

// Feature flags

	nextflow.preview.topic = true
	nextflow.preview.output = true

// Imports

	include { MAKE_HAPL } from '../modules/make-hapl.nf'
	include { MAKE_FILTER } from '../modules/make-filter.nf'
	include { PROCESS_GRAPH } from '../modules/process-graph.nf'
	include { COMPUTE_SNARLS } from '../modules/compute-snarls.nf'
	include { FASTP } from '../modules/fastp.nf'
	include { FASTQC as QC_RAW; FASTQC as QC_FASTP } from '../modules/fastqc.nf'
	include { FASTQ_MERGE_DEDUP } from '../modules/fastq-merge-dedup.nf'
	include { PANGENOME_MAP } from '../modules/pangenome-map.nf'
	include { VG_SURJECT } from '../modules/vg-surject.nf'
	include { BAM_DEDUP } from '../modules/bam-dedup.nf'
	include { PROFILE_PMD } from '../modules/profile-pmd.nf'
	include { VG_DECONSTRUCT } from '../modules/vg-deconstruct.nf'
	include { VG_GENOTYPE } from '../modules/vg-genotype.nf'
	include { FREEBAYES } from '../modules/freebayes.nf'
	include { DEEPVARIANT } from '../modules/deepvariant.nf'
	include { PROCESS_DEEPVARIANT } from '../modules/process-dv-vcf.nf'

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
					MAKE_HAPL(ch_gbz_graph, ch_types)
					ch_gbz_graph.combine(MAKE_HAPL.out.ch_hapl_indexes).collect()
						.map {element ->
							def ref = element[0]
							def indexes = element.size() == 3 ? [element[1], element[2]] : element[1] // Array == 3 if ref + two indexes, else == 2 for ref + index
							return [ref: ref, indexes: indexes]
						}
						.set { ch_indexed_graph }
				} else if ("${params.graphMode}" == "filter") {
					MAKE_FILTER(ch_gbz_graph, ch_types)
					ch_gbz_graph.combine(MAKE_FILTER.out.ch_filter_indexes).collect()
						.map {element ->
							def ref = element[0]
							def indexes = element.size() == 4 ? [element[1], element[2], element[3]] : [element[1], element[2]] // Array == 4 if ref + three indexes, else == 3 for ref + two indexes
							return [ref: ref, indexes: indexes]
						}
						.set { ch_indexed_graph }
				}

			// Report graph summary statistics & pull linear reference FASTAs

				PROCESS_GRAPH(ch_gbz_graph, ch_ref_path_files.collect())

			// Compute graph snarls for variant calling/genotyping tasks

				COMPUTE_SNARLS(ch_gbz_graph)

			// Run quality filtering on input reads

				FASTP(ch_samplesheet)

			// Run FASTQC on raw reads

				QC_RAW(ch_samplesheet)

			// Run FASTQC on filtered reads

				QC_FASTP(FASTP.out.ch_fastp_reads)

			// Merge and deduplicate FASTQs per sample

				FASTQ_MERGE_DEDUP(
					FASTP.out.ch_fastp_reads
						.map{ meta, fastqs -> [meta.subMap('id', 'type', 'merged'), fastqs] } // Create metadata subset to group on
						.groupTuple() // Group by sample
						.map{ meta, fastqs -> [meta, fastqs.flatten()] } // Flatten any nested lists
				)

			// Map reads to pangenome graph

				PANGENOME_MAP(FASTQ_MERGE_DEDUP.out.ch_sample_fastqs, ch_indexed_graph)

			// Surject mapped reads to reference paths

				VG_SURJECT(ch_gbz_graph.collect(), ch_ref_path_files.collect(), PANGENOME_MAP.out.ch_mapped_gam)

			// Secondary deduplication on surjected BAMs per sample

				BAM_DEDUP(ch_ref_path_files.collect(), VG_SURJECT.out.ch_surjected_bams)

			// Post-mortem damage assessment of reads

				PROFILE_PMD(ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas.collect(), BAM_DEDUP.out.ch_sample_dedup_indexed_bams)

			// Graph based variant calling

				VG_DECONSTRUCT(ch_gbz_graph, COMPUTE_SNARLS.out.ch_snarls, ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas)

			// Mapping based variant calling

				VG_GENOTYPE(ch_gbz_graph.collect(), COMPUTE_SNARLS.out.ch_snarls.collect(), ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas.collect(), PANGENOME_MAP.out.ch_mapped_gam)

				DEEPVARIANT(ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas.collect(), BAM_DEDUP.out.ch_sample_dedup_indexed_bams)

				PROCESS_DEEPVARIANT(ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas.collect(), DEEPVARIANT.out.ch_raw_deepvariant_vcf)

				FREEBAYES(ch_ref_path_files.collect(), PROCESS_GRAPH.out.ch_reference_fastas.collect(), BAM_DEDUP.out.ch_sample_dedup_indexed_bams)

			// Report skipped single library samples, as they were already deduplicated

				FASTQ_MERGE_DEDUP.out.ch_skipped_samples
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

				ch_graph_stats = PROCESS_GRAPH.out.ch_graph_stats
				ch_reference_fasta = PROCESS_GRAPH.out.ch_reference_fastas
				ch_library_fastp_report = FASTP.out.ch_library_fastp_report
				ch_sample_fastp_report = FASTQ_MERGE_DEDUP.out.ch_sample_fastp_report
				ch_fastqc_raw = QC_RAW.out.ch_fastqc
				ch_fastqc_fastp = QC_FASTP.out.ch_fastqc
				ch_alignment_stats = PANGENOME_MAP.out.ch_alignment_stats
				ch_mapped_gam = PANGENOME_MAP.out.ch_mapped_gam
				ch_raw_gam = PANGENOME_MAP.out.ch_raw_gam
				ch_sample_dedup_bams = BAM_DEDUP.out.ch_sample_dedup_bams
				ch_pmd_profiles = PROFILE_PMD.out.ch_pmd_profiles
				ch_vg_deconstruct_filtered_vcf = VG_DECONSTRUCT.out.ch_vg_deconstruct_filtered_vcf
				ch_vg_deconstruct_raw_vcf = VG_DECONSTRUCT.out.ch_vg_deconstruct_raw_vcf
				ch_vg_genotype_filtered_vcf = VG_GENOTYPE.out.ch_vg_genotype_filtered_vcf
				ch_vg_genotype_raw_vcf = VG_GENOTYPE.out.ch_vg_genotype_raw_vcf
				ch_freebayes_norm_vcf = FREEBAYES.out.ch_freebayes_norm_vcf
				ch_freebayes_raw_vcf = FREEBAYES.out.ch_freebayes_raw_vcf
				ch_deepvariant_html = DEEPVARIANT.out.ch_deepvariant_html
				ch_deepvariant_norm_vcf = PROCESS_DEEPVARIANT.out.ch_deepvariant_norm_vcf
				ch_deepvariant_raw_vcf = PROCESS_DEEPVARIANT.out.ch_deepvariant_raw_vcf
				ch_skipped_samples = ch_skipped_samples
				ch_versions = ch_versions

	}
