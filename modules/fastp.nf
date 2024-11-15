process FASTP {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/fastp:0.23.4--4ea6310369653ec7'
	publishDir path: 'output/quality_reports', mode: 'move', pattern: "*.fastp.html"

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	tuple val(meta), path("*.fastp*fq.gz"), emit: ch_fastp_reads
	path "*.fastp.json", emit: ch_fastp_report
	path "*.fastp.html"
	tuple val(task.process), val('fastp'), eval('fastp --version 2>&1 | sed "s/fastp //"'), topic: versions

	script:
	if (meta.type == "ancient")
		"""

		# Ancient DNA read QC, merge reads & discard unmerged

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --merge --merged_out ${meta.id}.${meta.repeat}.fastp.fq.gz --html ${meta.id}.${meta.repeat}.fastp.html --json ${meta.id}.${meta.repeat}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

		"""

	else if (meta.type == "modern")
		"""

		# Modern DNA read QC

			fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${meta.id}.${meta.repeat}.fastp.1.fq.gz --out2 ${meta.id}.${meta.repeat}.fastp.2.fq.gz --html ${meta.id}.${meta.repeat}.fastp.html --json ${meta.id}.${meta.repeat}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy ${params.dupCalcAccuracy} --correction --overrepresentation_analysis --length_required ${params.readDiscardLength} --thread ${task.cpus}

		"""

	else
		error ("Error: for '${meta.id}_repeat_${meta.repeat}' found the phrase '${meta.type}' in the samplesheet 'type' column, accepts 'ancient' or 'modern'.")

}
