process VGGRAPHCALL {

	// Call variants from paths in the graph. Ref allele is the reference path, alt alleles are from all other paths

	// Directives

	debug false
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bcftools_htslib_vcfbub_vg:cf972158c867084b'
	publishDir path: 'output/graph_calls', mode: 'move'

	// I/O & script

	input:
	path graph
	tuple path(reference_fasta), path(index)
	path snarls

	output:
	path "*.vcf.gz"
	path "vcf_information.txt"

	when:
	params.graphCall == true

	script:
	def basename = graph.baseName - '.gbz'

	if (params.referencePath == null)  // If user doesn't provide a reference path, use all reference paths by default
	"""

	# Get list of reference paths in graph

		references=`vg paths -x ${graph} --reference-paths --list`

	# Output raw VCF of graph Snarls (i.e., bubbles/superbubbles), relative to the given paths. Note: there is an experimental feature to write a nested VCF '--nested', but this isn't done in Minigraph-Cactus vcf pipeline

		vg deconstruct -t ${task.cpus} ${graph} -r ${snarls} --all-snarls --gbz-translation -p \$references | bgzip --threads ${task.cpus} > ${basename}.raw.vcf.gz

	# Index raw VCF

		tabix -p vcf ${basename}.raw.vcf.gz

	# Pop bubbles, i.e., remove nested variants at nesting level 'maxNestLevel', plus those over 'maxRefLength' in length, then normalise the VCF

		vcfbub --input ${basename}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f ${reference_fasta} | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.filtered.vcf.gz

	# Report user settings

		echo "VCF records are relative to the following reference paths:" > vcf_information.txt
		echo "\$references" >> vcf_information.txt
		echo "Graph call settings: maxNestLevel=${params.maxNestLevel}, maxRefLength=${params.maxRefLength}" >> vcf_information.txt

	"""

	else  // If the user provides a reference path, use only that path
	"""

	# Output raw VCF of graph Snarls (i.e., bubbles/superbubbles), relative to the given paths. Note: there is an experimental feature to write a nested VCF '--nested', but this isn't done in Minigraph-Cactus vcf pipeline

		vg deconstruct -t ${task.cpus} ${graph} -r ${snarls} --all-snarls --gbz-translation -p ${params.referencePath} | bgzip --threads ${task.cpus} > ${basename}.raw.vcf.gz

	# Index raw VCF

		tabix -p vcf ${basename}.raw.vcf.gz

	# Pop bubbles, i.e., remove nested variants at nesting level 'maxNestLevel', plus those over 'maxRefLength' in length, then normalise the VCF

		vcfbub --input ${basename}.raw.vcf.gz --max-level ${params.maxNestLevel} --max-ref-length ${params.maxRefLength} | bcftools norm -f ${reference_fasta} | bcftools sort | bgzip --threads ${task.cpus} > ${basename}.filtered.vcf.gz

	# Report user settings

		echo "VCF records are relative to the following reference paths:" > vcf_information.txt
		echo "${params.referencePath}" >> vcf_information.txt
		echo "In the case of troubleshooting empty vcf output, note that these are the reference paths in your graph:" >> vcf_information.txt
		vg paths -x ${graph} --reference-paths --list >> vcf_information.txt
		echo "Graph call settings: maxNestLevel=${params.maxNestLevel}, maxRefLength=${params.maxRefLength}" >> vcf_information.txt

	"""

}
