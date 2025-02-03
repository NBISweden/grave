process FASTP {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/fastp:0.24.0--0397de619771c7ae'
	publishDir path: 'output/quality_reports/fastp-library-level', mode: 'copy', pattern: "*.fastp.html.gz"

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	tuple val(meta), path("*.fastp*fq.gz"), emit: ch_fastp_reads
	path "*.fastp.html.gz"
	tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

	script:
	if (meta.type == "ancient" && meta.merged == false)
		"""

		# Ancient DNA read QC, merge reads & discard unmerged

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --merge --merged_out ${meta.id}.${meta.repeat}.fastp.fq.gz --html ${meta.id}.${meta.repeat}.fastp.html --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

			rm fastp.json

			gzip ${meta.id}.${meta.repeat}.fastp.html

		"""

	else if (meta.type == "modern" && meta.merged == false)
		"""

		# Modern DNA read QC

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${meta.id}.${meta.repeat}.fastp.1.fq.gz --out2 ${meta.id}.${meta.repeat}.fastp.2.fq.gz --html ${meta.id}.${meta.repeat}.fastp.html --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

			rm fastp.json

			gzip ${meta.id}.${meta.repeat}.fastp.html

		"""

	else if (meta.merged == true) // Same settings for ancient and modern
		"""

			fastp --in1 ${reads[0]} --out1 ${meta.id}.${meta.repeat}.fastp.fq.gz --html ${meta.id}.${meta.repeat}.fastp.html --dedup --dup_calc_accuracy ${params.dupCalcAccuracy}  --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

			rm fastp.json

			gzip ${meta.id}.${meta.repeat}.fastp.html

		"""

}
