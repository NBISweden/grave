process GPU_PREPROCESS {

    tag "${meta.read_group}"
    // NOTE: cpus handled in conf/tool_resources.config
    label 'process_medium'
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/kmc_vg:86557c7d07c6a6ce' :
        'community.wave.seqera.io/library/kmc_vg:03e2279b1340c073' }"

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    output:
    tuple val(meta), path("*.gbz"), path("*.dist"), path("*.min"), path("*.zipcodes"), emit: ch_sample_indexes
    tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"')     , topic: versions
    tuple val(task.process), val('vg') , eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def memory = task.memory.toGiga()
    def basename = graph.baseName - '.gbz'

    if (meta.type == "ancient") // Merged
        """
        # Generate kff index of the reads
        kmc -k${params.aDNAkmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.adna.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.aDNAkmerLength} --window-length ${params.aDNAwindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Clean
        rm *.kff
        """

    else if (meta.type == "modern" && meta.merged == false) // Paired
        """
        # Generate list of input read files
        echo -e "./${reads[0]}\n./${reads[1]}" > readfiles

        # Generate kff index of the reads
        kmc -k${params.modernKmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff @readfiles ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.modern.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Clean
        rm *.kff
        """

    else if (meta.type == "modern" && meta.merged == true) // Merged
        """
        # Generate kff index of the reads
        kmc -k${params.modernKmerLength} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.modern.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${basename}.${meta.read_group}.gbz ${graph}
        vg index --threads ${task.cpus} --dist-name ${basename}.${meta.read_group}.dist ${basename}.${meta.read_group}.gbz
        vg minimizer --threads ${task.cpus} --kmer-length ${params.modernKmerLength} --window-length ${params.modernWindowLength} --distance-index ${basename}.${meta.read_group}.dist --output-name ${basename}.${meta.read_group}.withzip.min --zipcode-name ${basename}.${meta.read_group}.zipcodes ${basename}.${meta.read_group}.gbz

        # Clean
        rm *.kff
        """

}
