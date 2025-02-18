#!/usr/bin/env nextflow

/* 
----------------------------------------------------------------------------------------

Main workflow

Grave: Graph Variant Explorer

GitHub: https://github.com/NBISweden/grave

Contributors:
- Cormac Kinsella (cormac.kinsella@nbis.se)
- Torsten Günther (torsten.guenther@ebc.uu.se)
- Marianne Dehasque (marianne.dehasque@ebc.uu.se)

----------------------------------------------------------------------------------------
*/

include { INITIALISE } from './subworkflows/initialise.nf'
include { GRAVE } from './workflows/grave.nf'

workflow {

	INITIALISE ()
	GRAVE ()

}
