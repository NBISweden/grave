process VGGRAPHCALL {

	// Call variants from paths in the graph

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
	path "vcf_filter_settings.txt"

	when:
	params.graphCall == true

	script:
	def basename = graph.baseName - '.gbz'

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

		echo "Graph call settings: maxNestLevel=${params.maxNestLevel}, maxRefLength=${params.maxRefLength}" > vcf_filter_settings.txt

	"""

}
