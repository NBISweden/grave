#!/usr/bin/env nextflow

/* 
----------------------------------------------------------------------------------------

Main workflow

pan-aDNA: Pangenomic analysis of ancient DNA

GitHub: https://github.com/NBISweden/pan-adna

Contributors:
- Cormac Kinsella (cormac.kinsella@nbis.se)
- Torsten Günther (torsten.guenther@ebc.uu.se)
- Marianne Dehasque (marianne.dehasque@ebc.uu.se)

----------------------------------------------------------------------------------------
*/

include { VERIFY } from './subworkflows/verify.nf'
include { PANADNA } from './workflows/panadna.nf'

workflow {

	VERIFY ()
	PANADNA ()

}
