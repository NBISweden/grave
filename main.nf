#!/usr/bin/env nextflow

// Workflow initialisation
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_grave/main'
// Reference file utilities
include { REFERENCE_UTILITIES     } from './subworkflows/local/utils_reference/main'
// Read preproceesing and QC
include { PREPROCESS_READS        } from './subworkflows/local/01_preprocess_reads/main'
// Map
include { ALIGN_READS             } from './subworkflows/local/02_align_reads/main'
// Merge BAMs
include { MERGE_BAMS              } from './subworkflows/local/03_merge_bams/main'
// Deduplicate BAMs
include { DEDUPLICATE_BAM         } from './subworkflows/local/04_deduplicate_bam/main'
// Damage profiling
include { PROFILE_PMD             } from './subworkflows/local/05_profile_pmd/main'
// Genotyping
include { GENOTYPE                } from './subworkflows/local/06_genotype/main'
// Variant calling
include { VARIANT_CALL            } from './subworkflows/local/07_variant_call/main'

// Entry workflow

	workflow {

		main:

			INITIALISE ()
			GRAVE (
				INITIALISE.out.ch_samplesheet,
				INITIALISE.out.ch_types,
				INITIALISE.out.ch_gbz_graph
			)

		publish:

			graph_stats = GRAVE.out.ch_graph_stats
			linear_references = GRAVE.out.ch_reference_fasta
			fastp_libraries = GRAVE.out.ch_library_fastp_report
			fastqc_raw = GRAVE.out.ch_fastqc_raw
			fastqc_fastp = GRAVE.out.ch_fastqc_fastp
			alignment_stats = GRAVE.out.ch_alignment_stats
			mapped_gam = GRAVE.out.ch_mapped_gam
			raw_gam = GRAVE.out.ch_raw_gam
			deduplicated_bams = GRAVE.out.ch_sample_dedup_bams
			dedup_metrics = GRAVE.out.ch_dedup_metrics
			post_mortem_damage = GRAVE.out.ch_pmd_profiles
			vg_graph_deconstruct_filtered_vcf = GRAVE.out.ch_vg_deconstruct_filtered_vcf
			vg_graph_deconstruct_raw_vcf = GRAVE.out.ch_vg_deconstruct_raw_vcf
			vg_genotype_filtered_vcf = GRAVE.out.ch_vg_genotype_filtered_vcf
			vg_genotype_raw_vcf = GRAVE.out.ch_vg_genotype_raw_vcf
			freebayes_normalised_vcf = GRAVE.out.ch_freebayes_norm_vcf
			freebayes_raw_vcf = GRAVE.out.ch_freebayes_raw_vcf
			deepvariant_report = GRAVE.out.ch_deepvariant_html
			deepvariant_normalised_vcf = GRAVE.out.ch_deepvariant_norm_vcf
			deepvariant_raw_vcf = GRAVE.out.ch_deepvariant_raw_vcf
			package_versions = GRAVE.out.ch_versions

	}

// Publish outputs

	output {

		graph_stats {
			path 'statistics/graph'
			mode 'copy'
			overwrite false
		}

		linear_references {
			path 'linear_references'
			mode 'copy'
			overwrite false
		}

		fastp_libraries {
			path 'quality_reports/fastp_library_level'
			mode 'copy'
			overwrite false
		}

		fastqc_raw {
			path 'quality_reports/fastqc/raw'
			mode 'copy'
			overwrite false
		}

		fastqc_fastp {
			path 'quality_reports/fastqc/fastp'
			mode 'copy'
			overwrite false
		}

		alignment_stats {
			path 'statistics/alignments'
			mode 'copy'
			overwrite false
		}

		mapped_gam {
			path 'mapped_files/gams'
			mode 'copy'
			overwrite false
		}

		raw_gam {
			path 'mapped_files/gams'
			mode 'copy'
			overwrite false
			enabled params.keepRawGam

		}

		deduplicated_bams {
			path 'mapped_files/bams'
			mode 'copy'
			overwrite false
		}

		dedup_metrics {
			path 'statistics/deduplication'
			mode 'copy'
			overwrite false
		}

		post_mortem_damage {
			path 'pmd_profiles'
			mode 'copy'
			overwrite false
		}

		vg_graph_deconstruct_filtered_vcf {
			path 'genotyping/graph'
			mode 'copy'
			overwrite false
		}

		vg_graph_deconstruct_raw_vcf {
			path 'genotyping/graph'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		vg_genotype_filtered_vcf {
			path 'genotyping/vg_genotype'
			mode 'copy'
			overwrite false
		}

		vg_genotype_raw_vcf {
			path 'genotyping/vg_genotype'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		freebayes_normalised_vcf {
			path 'variant_calling/freebayes'
			mode 'copy'
			overwrite false
		}

		freebayes_raw_vcf {
			path 'variant_calling/freebayes'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		deepvariant_report {
			path 'variant_calling/deepvariant'
			mode 'copy'
			overwrite false
		}

		deepvariant_normalised_vcf {
			path 'variant_calling/deepvariant'
			mode 'copy'
			overwrite false
		}

		deepvariant_raw_vcf {
			path 'variant_calling/deepvariant'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		package_versions {
			path 'package_versions'
			mode 'copy'
			overwrite false
		}

	}

// Email report

	if (params.email_report) {

		workflow.onComplete {

			// Prepare email content
			def workflow_status = workflow.success ? 'COMPLETED' : 'FAILED'
			def email_address = params.email
			def subject = "grave workflow run ${workflow.runName}: ${workflow_status}"
			def msg = """
			Pipeline execution summary
			---------------------------
			Run Name     : ${workflow.runName}
			Completed at : ${workflow.complete}
			Duration     : ${workflow.duration}
			Success      : ${workflow.success}
			Exit status  : ${workflow.exitStatus}
			Error report : ${workflow.errorReport ?: 'No errors'}
			"""
			.stripIndent()

			// Send the email
			sendMail(
				to: email_address,
				subject: subject,
				body: msg
			)

		}

	}
