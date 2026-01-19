process PANGENOME_MAP {

    tag "${meta.read_group}"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/kmc_vg:469fa513f88bd14f' :
        'community.wave.seqera.io/library/kmc_vg:51df7ac5d5cbd79d' }"

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    output:
    tuple val(meta), path("${meta.read_group}.filtered.gam"), emit: ch_mapped_gam
    path "${meta.read_group}.gam", optional: true, emit: ch_raw_gam
    path "${meta.read_group}_alignment-stats.txt", emit: ch_alignment_stats
    tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"'), topic: versions
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def memory = task.memory.toGiga()
    def basename = graph.baseName - '.gbz'

    if (meta.type == "ancient" && params.reference_type == "unfiltered_graph") // Ancient samples arrive merged, thus output not interleaved
        """
        # Generate kff index of the reads
        kmc -k${params.aDNAkmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.adna.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerMinimizer} --window-length ${params.aDNAwindowMinimizer} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.min ${basename}.${meta.read_group}.gbz

        # Map reads to graph (settings based on BWA aln)
        vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --fastq-in ${reads} --gbz-name ${basename}.${meta.read_group}.gbz --dist-name ${basename}.${meta.read_group}.dist --minimizer-name ${basename}.${meta.read_group}.min --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_alignment-stats.txt

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff
        """

    else if (meta.type == "ancient" && params.reference_type == "filtered_graph") // Ancient samples arrive merged, thus output not interleaved
        """
        # Map merged reads (settings based on BWA aln)
        vg giraffe --progress --mismatch 3 --gap-open 11 --gap-extend 4 --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.adna.min --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${graph} -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_alignment-stats.txt
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == false) // Arrives paired, output interleaved
        """
        # Generate list of input read files
        echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

        # Generate kff index of the reads
        kmc -k${params.modernKmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff @readfiles ${meta.read_group} .

        # Map paired-end reads (for modern reads the default Giraffe pipeline is appropriate. The mapping settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --kff-name ${meta.read_group}.kff --gbz-name ${graph} --haplotype-name *.modern.hapl --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics (the mapped graph in Giraffe workflow above is the subsampled one)
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_alignment-stats.txt

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff readfiles
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == false) // Arrives paired, output interleaved
        """
        # Map paired-end reads (default settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.min --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${graph} --interleaved-all -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_alignment-stats.txt
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == true) // Arrives merged, output not interleaved
        """
        # Generate kff index of the reads
        kmc -k${params.modernKmerHaplSubSam} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Map merged reads (for modern reads the default Giraffe pipeline is appropriate. The mapping settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads} --kff-name ${meta.read_group}.kff --gbz-name ${graph} --haplotype-name *.modern.hapl --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics (the mapped graph in Giraffe workflow above is the subsampled one)
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_alignment-stats.txt

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == true) // Arrives merged, output not interleaved
        """
        # Map merged reads (default settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.min --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Filter GAM
        vg filter ${args} ${args2} ${args3} -t ${task.cpus} -x ${graph} -r ${params.minimumScorePrimaryAlign} -fu -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_alignment-stats.txt
        """

}
