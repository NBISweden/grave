process FASTQC {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastqc:0.12.1--0827550dd72a3745'
	publishDir path: 'results/quality_reports/fastqc/fastp', mode: 'copy', pattern: "*fastp*_fastqc.zip"
	publishDir path: 'results/quality_reports/fastqc/raw', mode: 'copy', pattern: "*.zip", saveAs: { filename -> filename.contains("fastp") ? null : filename }

	// I/O & script

	input:
	tuple val(meta), path(raw_reads), path(fastp_reads)

	output:
	path "*fastqc.zip"
	tuple val(task.process), val('fastqc'), eval('fastqc --version | sed "s/.* v//"'), topic: versions

	script:
	"""

	# Run FastQC on raw and fastp processed reads

		fastqc --format fastq --threads ${task.cpus} ${raw_reads} ${fastp_reads}

	# Clean up

		rm *.html

	"""

}
