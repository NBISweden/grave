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
			GRAVE (INITIALISE.out.ch_samplesheet)

		publish:

			GRAVE.out.ch_versions >> 'package_versions'

	}

// Publish outputs

	output {

		package_versions {
			path 'package_versions'
			mode 'copy'
			overwrite true
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
