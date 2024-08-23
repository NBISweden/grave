#!/usr/bin/env nextflow

/* 
----------------------------------------------------------------------------------------
Central workflow

pan-aDNA: pangenomic analysis of ancient DNA

GitHub: https://github.com/NBISweden/pan-adna

Contributors:
- Cormac Kinsella (cormac.kinsella@nbis.se)
- FIXME:
----------------------------------------------------------------------------------------
*/

include { VERIFY } from './subworkflows/verify.nf'
include { PANADNA } from './workflows/panadna.nf'

workflow {

	VERIFY ()
	PANADNA ()

}
