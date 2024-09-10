process FASTP {

	// Directives

	debug false
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/fastp:0.23.4--4ea6310369653ec7'

	// I/O & script

	input:
	tuple val(meta), path(reads)

	output:
	tuple val(meta), path("*.fastp*fq.gz"), emit: ch_fastp_reads
	path "*.fastp.json", emit: ch_fastp_report

	script:
	if (meta.type == "ancient")
		"""

		# merge reads, trim adapters, deduplicate, overlapping base correction, overrepresentation analysis, trim polyG
		# Unmerged reads are discarded currently as these represent longer fragments, thus more likely contamination

		fastp --in1 ${reads[0]} --in2 ${reads[1]} --merge --merged_out ${meta.id}.fastp.fq.gz --html ${meta.id}.fastp.html --json ${meta.id}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy $params.dup_calc_accuracy --correction --overrepresentation_analysis --length_required $params.read_discard_length --thread ${task.cpus}

		"""

	else if (meta.type == "modern")
		"""
	
		fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 ${meta.id}.fastp.1.fq.gz --out2 ${meta.id}.fastp.2.fq.gz --html ${meta.id}.fastp.html --json ${meta.id}.fastp.json --detect_adapter_for_pe --dedup --dup_calc_accuracy $params.dup_calc_accuracy --correction --overrepresentation_analysis --length_required $params.read_discard_length --thread ${task.cpus}

		"""

	else
		error ("Error: for '$meta.id' found the phrase '$meta.type' in the samplesheet type column, accepts 'ancient' or 'modern'.")

}
