#!/usr/bin/env nextflow

/* 
----------------------------------------------------------------------------------------

Graph Variant Explorer

NBISweden/Grave

GitHub: https://github.com/NBISweden/grave

Contributors:
- Cormac Kinsella (cormac.kinsella@nbis.se)
- Torsten Günther (torsten.guenther@ebc.uu.se)
- Marianne Dehasque (marianne.dehasque@ebc.uu.se)

----------------------------------------------------------------------------------------
*/

// Imports

	include { INITIALISE } from './subworkflows/initialise.nf'
	include { GRAVE } from './workflows/grave.nf'

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
			GRAVE.out.ch_graph_stats >> 'graph_stats'
			GRAVE.out.ch_library_fastp_report >> 'fastp_libraries'
			GRAVE.out.ch_sample_fastp_report >> 'fastp_merged_samples'
			GRAVE.out.ch_fastqc_raw >> 'fastqc_raw'
			GRAVE.out.ch_fastqc_fastp >> 'fastqc_fastp'
			GRAVE.out.ch_alignment_stats >> 'alignment_stats'
			GRAVE.out.ch_mapped_gam >> 'mapped_gam'
			GRAVE.out.ch_raw_gam >> 'raw_gam'
			GRAVE.out.ch_sample_dedup_bams >> 'mapped_bams'
			GRAVE.out.ch_pmd_profiles >> 'post_mortem_damage'
			GRAVE.out.ch_vg_graph_call_filtered_vcf >> 'vg_graph_call_filtered_vcf'
			GRAVE.out.ch_vg_graph_call_raw_vcf >> 'vg_graph_call_raw_vcf'
			GRAVE.out.ch_vg_map_call_filtered_vcf >> 'vg_map_call_filtered_vcf'
			GRAVE.out.ch_vg_map_call_raw_vcf >> 'vg_map_call_raw_vcf'
			GRAVE.out.ch_freebayes_norm_vcf >> 'freebayes_normalised_vcf'
			GRAVE.out.ch_freebayes_raw_vcf >> 'freebayes_raw_vcf'
			GRAVE.out.ch_deepvariant_html >> 'deepvariant_report'
			GRAVE.out.ch_deepvariant_norm_vcf >> 'deepvariant_normalised_vcf'
			GRAVE.out.ch_deepvariant_raw_vcf >> 'deepvariant_raw_vcf'
			GRAVE.out.ch_skipped_samples >> 'skip_fastp_merge_samples'
			GRAVE.out.ch_versions >> 'package_versions'

	}

// Publish outputs

	output {

		graph_stats {
			path 'statistics/graph'
			mode 'copy'
			overwrite false
		}

		fastp_libraries {
			path 'quality_reports/fastp-library-level'
			mode 'copy'
			overwrite false
		}

		fastp_merged_samples {
			path 'quality_reports/fastp-sample-level'
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
			path 'statistics/mapped_samples'
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

		mapped_bams {
			path 'mapped_files/bams'
			mode 'copy'
			overwrite false
		}

		post_mortem_damage {
			path 'pmd_profiles'
			mode 'copy'
			overwrite false
		}

		vg_graph_call_filtered_vcf {
			path 'variant_calling/graph'
			mode 'copy'
			overwrite false
		}

		vg_graph_call_raw_vcf {
			path 'variant_calling/graph'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		vg_map_call_filtered_vcf {
			path 'variant_calling/mapped_samples/vg-call'
			mode 'copy'
			overwrite false
		}

		vg_map_call_raw_vcf {
			path 'variant_calling/mapped_samples/vg-call'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		freebayes_normalised_vcf {
			path 'variant_calling/mapped_samples/freebayes'
			mode 'copy'
			overwrite false
		}

		freebayes_raw_vcf {
			path 'variant_calling/mapped_samples/freebayes'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		deepvariant_report {
			path 'quality_reports/deepvariant'
			mode 'copy'
			overwrite false
		}

		deepvariant_normalised_vcf {
			path 'variant_calling/mapped_samples/deepvariant'
			mode 'copy'
			overwrite false
		}

		deepvariant_raw_vcf {
			path 'variant_calling/mapped_samples/deepvariant'
			mode 'copy'
			overwrite false
			enabled params.keepRawVcf
		}

		skip_fastp_merge_samples {
			path 'quality_reports/fastp-sample-level'
			mode 'copy'
			overwrite false
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
