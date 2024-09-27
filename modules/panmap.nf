	// TODO: figure out which output format is most useful. Default is 1. What can that be used with? I think some of the other downstreams need bam?
	// TODO: Not fully solved issue with mapping simulated reads -> vg isn't getting a fragment length distribution, may be linked to distance index generation (settings not easily accessible to the user in giraffe). This causes it to fail paired end mapping and revert to single ended, as it "Cannot cluster reads with a fragment distance smaller than read distance". Since read distance is set to a limit of 200 by default, and the failure to get a distribution defaults it to 0 with stdev 1 this issue is introduced. Could override it, but what would be biologically valid settings? "Fragment length distribution: mean=0, stdev=1, Fragment distance limit: 2, read distance limit: 200". Relevant settings: --fragment-mean, --fragment-stdev, --distance-limit.

process PANMAP {

	// Directives

	debug true
	tag "$meta.id"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:1f2db4fcec341609'

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(reference), path(indexes)

	script:
	// Create a numeric variable with the available memory (i.e., strip off the trailing units)
	def memory = task.memory.toGiga()

	if (meta.type == "ancient" && params.referenceMode == "haplo")
		"""

		# Generate kff index

		kmc -k29 -ci${params.kmerMinimumOccurences} -t${task.cpus} -m$memory -sm -fq -okff $reads $meta.id .

		# Map merged reads (settings based on BWA aln)

		vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 250 --fastq-in $reads --kff-name ${meta.id}.kff --gbz-name $reference --haplotype-name $indexes --output-format GAM --threads ${task.cpus} > ${meta.id}.gam

		# Remove sample specific indexes

		rm *.$meta.id.*

		"""

	else if (meta.type == "modern" && params.referenceMode == "haplo")
		"""

		# Generate list of input read files

		echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

		# Generate kff index

		kmc -k29 -ci${params.kmerMinimumOccurences} -t${task.cpus} -m$memory -sm -fq -okff @readfiles $meta.id .

		# Map paired-end reads (default settings are equivalent to BWA mem)

		vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.id}.kff --gbz-name $reference --haplotype-name $indexes --output-format GAM --threads ${task.cpus} > ${meta.id}.gam

		# Remove sample specific indexes

		rm *.$meta.id.*

		"""

	else if (meta.type == "ancient" && params.referenceMode == "filter")
		"""

		# Map merged reads (settings based on BWA aln)

		vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 250 --fastq-in $reads --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format GAM --threads ${task.cpus} > ${meta.id}.gam

		"""

	else if (meta.type == "modern" && params.referenceMode == "filter")
		"""

		# Map paired-end reads (default settings are equivalent to BWA mem)

		vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name $reference --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format GAM --threads ${task.cpus} > ${meta.id}.gam

		"""

}
