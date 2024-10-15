process FASTQC {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastqc:0.12.1--0827550dd72a3745'

	// I/O & script

    input:
    tuple val(meta), path(raw_reads)
	tuple val(meta), path(fastp_reads)

	output:
	tuple val(meta), path("*_?.raw.fq.gz"), emit: ch_renamed_raw
	path "*fastqc.zip", emit: ch_fastqc_report

	script:
	"""

	# Rename raw reads and capture in an output channel

		mv ${raw_reads[0]} ${meta.id}_1.raw.fq.gz
		mv ${raw_reads[1]} ${meta.id}_2.raw.fq.gz

	# Run FastQC on raw and fastp processed reads

		fastqc --format fastq --threads ${task.cpus} *.raw.fq.gz $fastp_reads

    """

}
