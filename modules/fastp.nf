process FASTP {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/fastp:0.23.4--4ea6310369653ec7'

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	tuple val(meta), path("*.fastp*fq.gz"), emit: ch_fastp_reads
	path "*.fastp.json", emit: ch_fastp_report
	tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

	script:
	if (meta.type == "ancient")
		"""

		# Ancient DNA read QC, merge reads & discard unmerged

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --merge --merged_out ${meta.id}.fastp.fq.gz --html ${meta.id}.fastp.html --json ${meta.id}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

		"""

	else if (meta.type == "modern")
		"""

		# Modern DNA read QC

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${meta.id}.fastp.1.fq.gz --out2 ${meta.id}.fastp.2.fq.gz --html ${meta.id}.fastp.html --json ${meta.id}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

		"""

	else
		error ("Error: for '${meta.id}' found the phrase '${meta.type}' in the samplesheet type column, accepts 'ancient' or 'modern'.")

}
