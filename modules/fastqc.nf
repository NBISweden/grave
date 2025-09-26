process FASTQC {

	// Directives

	debug false
	tag "${meta.read_group}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastqc:0.12.1--0827550dd72a3745'

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	tuple path("*fastqc.zip"), path("*.html"), emit: ch_fastqc
	tuple val(task.process), val('fastqc'), eval('fastqc --version | sed "s/.* v//"'), topic: versions

	script:
	def args = task.ext.args ?: ''

	"""

	# Run FastQC

		fastqc --format fastq --threads ${task.cpus} ${reads}

	"""

}
