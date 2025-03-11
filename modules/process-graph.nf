process PROCESS_GRAPH {

	// Directives

	debug false
	tag "${graph.baseName}_graph"
	label 'process_low'
	container 'oras://community.wave.seqera.io/library/samtools_vg:708cddc079bf2492'

	// I/O & script

	input:
	path graph
	path ref_path_files

	output:
	path "*_graph-*.txt*", emit: ch_graph_stats
	tuple path("*.fasta"), path("*.fasta.fai"), emit: ch_reference_fastas
	tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
	tuple val(task.process), val('samtools'), eval('samtools version | head -n 1 | sed "s/samtools //"'), topic: versions

	script:
	def basename = graph.baseName - '.gbz'

	if (!params.multiRef)	// Assume single reference sample, extract all reference paths
		"""

		# Report graph summary statistics

			echo "Pangenome graph file:" > ${basename}_graph-stats.txt && echo ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt
			echo "Graph statistics:" >> ${basename}_graph-stats.txt && vg stats --threads ${task.cpus} -zlLHTA ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt

		# Report graph metadata to separate file

			vg paths --metadata -x ${graph} > ${basename}_graph-metadata.txt
			gzip ${basename}_graph-metadata.txt

		# Extract reference sample paths as FASTA

			vg paths --reference-paths --extract-fasta -x ${graph} > reference.fasta

		# Index reference FASTA

			samtools faidx reference.fasta

		"""

	else if (params.multiRef)	// Assume multiple reference samples, extract provided reference paths for each sample
		"""

		# Report graph summary statistics

			echo "Pangenome graph file:" > ${basename}_graph-stats.txt && echo ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt
			echo "Graph statistics:" >> ${basename}_graph-stats.txt && vg stats -zlLHTA ${graph} >> ${basename}_graph-stats.txt && echo >> ${basename}_graph-stats.txt

		# Report graph metadata to separate file

			vg paths --metadata -x ${graph} > ${basename}_graph-metadata.txt
			gzip ${basename}_graph-metadata.txt


		# Extract provided reference paths as FASTA

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					vg paths --paths-file \$i --extract-fasta -x ${graph} > \$prefix.fasta
				done

		# Index reference FASTAs

			for i in *.fasta
				do
					samtools faidx \$i
				done

		"""

}
