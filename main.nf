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

include { VERIFY } from './subworkflows/verify.nf'
include { GRAVE } from './workflows/grave.nf'

workflow {

	VERIFY ()
	GRAVE ()

}
