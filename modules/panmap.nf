process PANMAP {

	// Directives

	debug false
	tag "${meta.id}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/kmc_vg:71fb384e609a2165'
	publishDir path: 'output/mapped_files/gams', mode: 'copy', pattern: "*.filtered.gam"
	publishDir path: 'output/statistics/mapped_samples', mode: 'copy', pattern: "*_alignment-stats.txt"

	// I/O & script

	input:
	tuple val(meta), path(reads)
	tuple path(graph), path(indexes)

	output:
	tuple val(meta), path("${meta.id}.filtered.gam"), emit: ch_mapped_gam
	path "*_alignment-stats.txt"
	tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"'), topic: versions
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

	script:
	def memory = task.memory.toGiga()
	def basename = graph.baseName - '.gbz'

	if (meta.type == "ancient" && params.graphMode == "haplo") // Ancient samples arrive merged, thus output not interleaved
		"""

		# Generate kff index of the reads

			kmc -k${params.aDNAkmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.id} .

		# Generate the subsampled graph and index it

			vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.adna.hapl --kmer-input ${meta.id}.kff --gbz-output ${basename}.${meta.id}.gbz ${graph}
			vg index --threads ${task.cpus} --dist-name ${basename}.${meta.id}.dist ${basename}.${meta.id}.gbz
			vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.${meta.id}.dist --output-name ${basename}.${meta.id}.min ${basename}.${meta.id}.gbz

		# Map reads to graph (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in ${reads} --gbz-name ${basename}.${meta.id}.gbz --dist-name ${basename}.${meta.id}.dist --minimizer-name ${basename}.${meta.id}.min --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${basename}.${meta.id}.gbz -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.filtered.gam ${basename}.${meta.id}.gbz > ${meta.id}_alignment-stats.txt

		# Remove sample specific indexes

			rm *.${meta.id}.* *.kff

		"""

	else if (meta.type == "ancient" && params.graphMode == "filter") // Ancient samples arrive merged, thus output not interleaved
		"""

		# Map merged reads (settings based on BWA aln)

			vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --max-fragment-length 301 --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.adna.min --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${graph} -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.filtered.gam ${graph} > ${meta.id}_alignment-stats.txt

		"""

	else if (meta.type == "modern" && params.graphMode == "haplo" && meta.merged == false) // Arrives paired, output interleaved
		"""

		# Generate list of input read files

			echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

		# Generate kff index of the reads

			kmc -k${params.modernKmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff @readfiles ${meta.id} .

		# Map paired-end reads (for modern reads the default Giraffe pipeline is appropriate. The mapping settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.id}.kff --gbz-name ${graph} --haplotype-name *.modern.hapl --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${basename}.${meta.id}.gbz --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics (the mapped graph in Giraffe workflow above is the subsampled one)

			vg stats --alignments ${meta.id}.filtered.gam ${basename}.${meta.id}.gbz > ${meta.id}_alignment-stats.txt

		# Remove sample specific indexes

			rm *.${meta.id}.* *.kff readfiles

		"""

	else if (meta.type == "modern" && params.graphMode == "filter" && meta.merged == false) // Arrives paired, output interleaved
		"""

		# Map paired-end reads (default settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.min --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${graph} --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.filtered.gam ${graph} > ${meta.id}_alignment-stats.txt

		"""

	else if (meta.type == "modern" && params.graphMode == "haplo" && meta.merged == true) // Arrives merged, output not interleaved
		"""

		# Generate kff index of the reads

			kmc -k${params.modernKmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.id} .

		# Map merged reads (for modern reads the default Giraffe pipeline is appropriate. The mapping settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads} --kff-name ${meta.id}.kff --gbz-name ${graph} --haplotype-name *.modern.hapl --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${basename}.${meta.id}.gbz -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics (the mapped graph in Giraffe workflow above is the subsampled one)

			vg stats --alignments ${meta.id}.filtered.gam ${basename}.${meta.id}.gbz > ${meta.id}_alignment-stats.txt

		# Remove sample specific indexes

			rm *.${meta.id}.* *.kff

		"""

	else if (meta.type == "modern" && params.graphMode == "filter" && meta.merged == true) // Arrives merged, output not interleaved
		"""

		# Map merged reads (default settings are equivalent to BWA mem)

			vg giraffe --progress --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.min --output-format GAM --threads ${task.cpus} --sample ${meta.id} > ${meta.id}.gam

		# Filter GAM (remove unmapped reads, apply MAPQ filter, minimum primary alignment score, defray ambiguous alignment ends)

			vg filter -t ${task.cpus} -x ${graph} -r ${params.minimumScorePrimaryAlign} -fu --only-mapped -q ${params.minimumMapQFilter} -D 999 -v ${meta.id}.gam > ${meta.id}.filtered.gam

		# Remove raw GAM

			rm ${meta.id}.gam

		# Report mapping statistics

			vg stats --alignments ${meta.id}.filtered.gam ${graph} > ${meta.id}_alignment-stats.txt

		"""

}
