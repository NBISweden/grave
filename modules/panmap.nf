process PANMAP {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:353e0f1b839eee94'
	publishDir path: 'output/mapped_files/gams', mode: 'copy', pattern: "*.gam"
	publishDir path: 'output/statistics/mapped_samples', mode: 'move', pattern: "*_alignment-stats.txt"

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(graph), path(indexes)

	output:
	tuple val(meta), path("${meta.id}.${meta.repeat}.gam")
	tuple val(meta), path("${meta.id}.${meta.repeat}.filtered.gam"), emit: ch_mapped_gam
	path "*_alignment-stats.txt"
	tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"'), topic: versions
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	def memory = task.memory.toGiga()
	def basename = graph.baseName - '.gbz'

	if (meta.type == "ancient" && params.graphMode == "haplo")
		"""

		# Generate kff index of the reads

			kmc -k${params.aDNAkmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.id}.${meta.repeat} .

		# Generate the subsampled graph and index it

			vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input ${indexes[0]} --kmer-input ${meta.id}.${meta.repeat}.kff --gbz-output ${basename}.${meta.id}.${meta.repeat}.gbz ${graph}
			vg index --threads ${task.cpus} --dist-name ${basename}.${meta.id}.${meta.repeat}.dist ${basename}.${meta.id}.${meta.repeat}.gbz
			vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.${meta.id}.${meta.repeat}.dist --output-name ${basename}.${meta.id}.${meta.repeat}.min ${basename}.${meta.id}.${meta.repeat}.gbz

		# Map merged reads to graph (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in ${reads} --gbz-name ${basename}.${meta.id}.${meta.repeat}.gbz --dist-name ${basename}.${meta.id}.${meta.repeat}.dist --minimizer-name ${basename}.${meta.id}.${meta.repeat}.min --output-format GAM --threads ${task.cpus} --sample ${meta.id}.${meta.repeat} --read-group ${meta.read_group} > ${meta.id}.${meta.repeat}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${basename}.${meta.id}.${meta.repeat}.gbz -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.${meta.repeat}.gam > ${meta.id}.${meta.repeat}.filtered.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.${meta.repeat}.filtered.gam ${basename}.${meta.id}.${meta.repeat}.gbz > ${meta.id}.${meta.repeat}_alignment-stats.txt

		# Remove sample specific indexes

			rm *.${meta.id}.${meta.repeat}.* *.kff

		"""

	else if (meta.type == "modern" && params.graphMode == "haplo")
		"""

		# Generate list of input read files

			echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

		# Generate kff index of the reads

			kmc -k${params.modernKmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff @readfiles ${meta.id}.${meta.repeat} .

		# Map paired-end reads (for modern reads the default Giraffe pipeline is appropriate. The mapping settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.id}.${meta.repeat}.kff --gbz-name ${graph} --haplotype-name ${indexes[1]} --output-format GAM --threads ${task.cpus} --sample ${meta.id}.${meta.repeat} --read-group ${meta.read_group} > ${meta.id}.${meta.repeat}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${basename}.${meta.id}.${meta.repeat}.gbz --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.${meta.repeat}.gam > ${meta.id}.${meta.repeat}.filtered.gam

		# Report mapping statistics (the mapped graph in Giraffe workflow above is the subsampled one)

			vg stats --alignments ${meta.id}.${meta.repeat}.filtered.gam ${basename}.${meta.id}.${meta.repeat}.gbz > ${meta.id}.${meta.repeat}_alignment-stats.txt

		# Remove sample specific indexes

			rm *.${meta.id}.${meta.repeat}.* *.kff

		"""

	else if (meta.type == "ancient" && params.graphMode == "filter")
		"""

		# Map merged reads (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in ${reads} --gbz-name ${graph} --dist-name ${indexes[0]} --minimizer-name ${indexes[1]} --output-format GAM --threads ${task.cpus} --sample ${meta.id}.${meta.repeat} --read-group ${meta.read_group} > ${meta.id}.${meta.repeat}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${graph} -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.${meta.repeat}.gam > ${meta.id}.${meta.repeat}.filtered.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.${meta.repeat}.filtered.gam ${graph} > ${meta.id}.${meta.repeat}_alignment-stats.txt

		"""

	else if (meta.type == "modern" && params.graphMode == "filter")
		"""

		# Map paired-end reads (default settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name ${graph} --dist-name ${indexes[0]} --minimizer-name ${indexes[2]} --output-format GAM --threads ${task.cpus} --sample ${meta.id}.${meta.repeat} --read-group ${meta.read_group} > ${meta.id}.${meta.repeat}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${graph} --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.${meta.repeat}.gam > ${meta.id}.${meta.repeat}.filtered.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.${meta.repeat}.filtered.gam ${graph} > ${meta.id}.${meta.repeat}_alignment-stats.txt

		"""

}
