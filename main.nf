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
			GRAVE ()

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
