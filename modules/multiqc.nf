process MULTIQC {

	// Directives

	debug false
	label 'process_single'
	container 'oras://community.wave.seqera.io/library/multiqc:1.25.1--f0e743d16869c0bf'

	// I/O & script

	input:
	path fastp_jsons
	path fastqc_reports

	output:
	path "multiqc_report.html"
	tuple val(task.process), val('multiqc'), eval('multiqc --version | sed "s/.*version //"'), topic: versions

	script:
	"""
	# TODO: troubleshoot output - currently suggests it's treating the raw reads as the fastp processed output. May be fastp issue rather than multiqc

		multiqc --force --fullnames --clean-up --no-version-check .

	"""

}
