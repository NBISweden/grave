process GIRAFFE {

    tag "${meta.read_group}"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/kmc_vg:d27de6645074ab5c' :
        'community.wave.seqera.io/library/kmc_vg:57c489c0e1d4e955' }"

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    output:
    tuple val(meta), path("${meta.read_group}.filtered.gam"), env('ALIGNMENT_COUNT'), emit: ch_gam_counts
    path "${meta.read_group}.gam", optional: true, emit: ch_raw_gam
    path "${meta.read_group}_raw-alignment-stats.txt", emit: ch_raw_alignment_stats
    path "${meta.read_group}_filtered-alignment-stats.txt", emit: ch_filtered_alignment_stats
    tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"'), topic: versions
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def args4 = task.ext.args4 ?: ''
    def memory = task.memory.toGiga()
    def basename = graph.baseName - '.gbz'

    if (meta.type == "ancient" && params.reference_type == "unfiltered_graph") // Ancient samples arrive merged, thus output not interleaved
        """
        # Generate kff index of the reads
        kmc -k${params.aDNAkmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.adna.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Map reads to graph
        vg giraffe --progress --mismatch ${params.aDNA_mismatch_penalty} --gap-open ${params.aDNA_gap_open_penalty} --gap-extend ${params.aDNA_gap_extend_penalty} --fastq-in ${reads} --gbz-name ${basename}.${meta.read_group}.gbz --dist-name ${basename}.${meta.read_group}.dist --minimizer-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff
        """

    else if (meta.type == "ancient" && params.reference_type == "filtered_graph") // Ancient samples arrive merged, thus output not interleaved
        """
        # Map merged reads
        vg giraffe --progress --mismatch ${params.aDNA_mismatch_penalty} --gap-open ${params.aDNA_gap_open_penalty} --gap-extend ${params.aDNA_gap_extend_penalty} --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.adna.withzip.min --zipcode-name *.adna.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${graph} > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${graph} -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == false) // Arrives paired, output interleaved
        """
        # Generate list of input read files
        echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

        # Generate kff index of the reads
        kmc -k${params.modernKmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff @readfiles ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.modern.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Map paired-end reads
        vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name ${basename}.${meta.read_group}.gbz --dist-name ${basename}.${meta.read_group}.dist --minimizer-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz --interleaved-all -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff readfiles
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == false) // Arrives paired, output interleaved
        """
        # Map paired-end reads (default settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads[0]} --fastq-in ${reads[1]} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.withzip.min --zipcode-name *.modern.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${graph} > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${graph} --interleaved-all -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')
        """

    else if (meta.type == "modern" && params.reference_type == "unfiltered_graph" && meta.merged == true) // Arrives merged, output not interleaved
        """
        # Generate kff index of the reads
        kmc -k${params.modernKmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.modern.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Map merged reads
        vg giraffe --progress --fastq-in ${reads} --gbz-name ${basename}.${meta.read_group}.gbz --dist-name ${basename}.${meta.read_group}.dist --minimizer-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${basename}.${meta.read_group}.gbz -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${basename}.${meta.read_group}.gbz > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')

        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff
        """

    else if (meta.type == "modern" && params.reference_type == "filtered_graph" && meta.merged == true) // Arrives merged, output not interleaved
        """
        # Map merged reads (default settings are equivalent to BWA mem)
        vg giraffe --progress --fastq-in ${reads} --gbz-name ${graph} --dist-name *.dist --minimizer-name *.modern.withzip.min --zipcode-name *.modern.zipcodes --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

        # Report raw mapping statistics
        vg stats --alignments ${meta.read_group}.gam ${graph} > ${meta.read_group}_raw-alignment-stats.txt

        # Filter GAM
        vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${graph} -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

        # Remove raw GAM unless overridden
        if [ "${params.keepRawGam}" != "true" ]
            then
                rm ${meta.read_group}.gam
        fi

        # Report filtered mapping statistics
        vg stats --alignments ${meta.read_group}.filtered.gam ${graph} > ${meta.read_group}_filtered-alignment-stats.txt

        # Get alignment count (to branch passed/failed samples)
        ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}_filtered-alignment-stats.txt | awk '{print \$3}')
        """

}
