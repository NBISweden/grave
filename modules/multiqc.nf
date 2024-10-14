process MULTIQC {

	// Directives

	debug true
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/multiqc:1.24.1--438afbfaf9badab9'

	// I/O & script

	input:
	path fastp_jsons
	path fastqc_reports

	output:
	path "multiqc_report.html"

	script:
	"""
	# TODO: troubleshoot output - currently suggests it's treating the raw reads as the fastp processed output. May be fastp issue rather than multiqc

	multiqc --force --fullnames --clean-up --no-version-check .

	"""

}
