process FASTQC {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastqc:0.12.1--0827550dd72a3745'

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	path "*fastqc.zip", emit: ch_fastqc
	tuple val(task.process), val('fastqc'), eval('fastqc --version | sed "s/.* v//"'), topic: versions

	script:
	def args = task.ext.args ?: ''

	"""

	# Remove empty files (most common in unmerged aDNA output from fastp)

		for file in *.fq.gz *.fastq.gz
			do
				if [ -f "\$file" ] && [ ! -s "\$file" ]; then
					rm \$file
					echo "Removed empty file \$file."
				fi
			done

	# Run FastQC

		fastqc --format fastq --threads ${task.cpus} *.fq.gz  *.fastq.gz

	# Clean up

		rm *.html

	"""

}
