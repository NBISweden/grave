process GIRAFFE {

    tag "${meta.read_group}"
    // NOTE: all resources handled in conf/tool_resources.config
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/kmc_vg:d27de6645074ab5c' :
        'community.wave.seqera.io/library/kmc_vg:57c489c0e1d4e955' }"

    input:
    tuple val(meta), path(reads)
    tuple path(graph), path(indexes)

    output:
    tuple val(meta), path("${meta.read_group}.filtered.gam"), env('ALIGNMENT_COUNT'), emit: ch_gam_counts
    path "${meta.read_group}.gam", optional: true, emit: ch_raw_gam
    path "*vg-stats"             , emit: ch_gam_stats
    tuple val(task.process), val('kmc'), eval('kmc version | head -n 1 | sed "s/.*ver. //; s/ .*//"')     , topic: versions
    tuple val(task.process), val('vg') , eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def args4 = task.ext.args4 ?: ''
    def memory = task.memory.toGiga()
    def basename = graph.baseName - '.gbz'

    def ancient = meta.type == "ancient"
    def paired = meta.type == "modern" && !meta.merged // Modern unmerged reads arrive paired, output interleaved. Ancient and merged reads are not interleaved
    def unfiltered = params.reference_type == "unfiltered_graph"
    def hap_set = ancient ? "adna" : "modern"
    def kmer_length = ancient ? params.aDNAkmerLength : params.modernKmerLength
    def window_length = ancient ? params.aDNAwindowLength : params.modernWindowLength
    def mapping_args = ancient ? "--mismatch ${params.aDNA_mismatch_penalty} --gap-open ${params.aDNA_gap_open_penalty} --gap-extend ${params.aDNA_gap_extend_penalty}" : ''
    def fastq_in = paired ? "--fastq-in ${reads[0]} --fastq-in ${reads[1]}" : "--fastq-in ${reads}"
    def filter_interleaved = paired ? '--interleaved-all' : ''

    // Unfiltered graphs: subsample & index the graph per sample. Filtered graphs: use the provided indexes
    def gbz = unfiltered ? "${basename}.${meta.read_group}.gbz" : "${graph}"
    def dist = unfiltered ? "${basename}.${meta.read_group}.dist" : "*.dist"
    def minimizer = unfiltered ? "${basename}.${meta.read_group}.withzip.min" : "*.${hap_set}.withzip.min"
    def zipcodes = unfiltered ? "${basename}.${meta.read_group}.zipcodes" : "*.${hap_set}.zipcodes"

    def read_list = paired ? "# Generate list of input read files\necho -e \"./${reads[0]}\n./${reads[1]}\" > readfiles" : ''
    def index_graph = !unfiltered ? '' : """
        ${read_list}

        # Generate kff index of the reads
        kmc -k${kmer_length} -ci${params.kffKmerMinimum} -t${task.cpus} -m${memory} -sm -fq -okff ${paired ? '@readfiles' : reads} ${meta.read_group} .

        # Generate the subsampled graph and index it
        vg haplotypes --threads ${task.cpus} --verbosity 2 --include-reference --diploid-sampling --haplotype-input *.${hap_set}.hapl --kmer-input ${meta.read_group}.kff --gbz-output ${gbz} ${graph}
        vg index --threads ${task.cpus} --dist-name ${dist} ${gbz}
        vg minimizer --threads ${task.cpus} --kmer-length ${kmer_length} --window-length ${window_length} --distance-index ${dist} --output-name ${minimizer} --zipcode-name ${zipcodes} ${gbz}
    """
    def cleanup = !unfiltered ? '' : """
        # Remove sample specific indexes
        rm *.${meta.read_group}.* *.kff ${paired ? 'readfiles' : ''}
    """
    """
    ${index_graph}
    # Map reads to graph
    vg giraffe --progress ${mapping_args} ${fastq_in} --gbz-name ${gbz} --dist-name ${dist} --minimizer-name ${minimizer} --zipcode-name ${zipcodes} --output-format GAM --threads ${task.cpus} > ${meta.read_group}.gam

    # Report raw mapping statistics
    if [ "${params.rawMapStats}" == "true" ]
        then
            vg stats --alignments ${meta.read_group}.gam ${gbz} > ${meta.read_group}.raw.gam.vg-stats
    fi

    # Filter GAM
    vg filter ${args} ${args2} ${args3} ${args4} -t ${task.cpus} -x ${gbz} ${filter_interleaved} -v ${meta.read_group}.gam > ${meta.read_group}.filtered.gam

    # Remove raw GAM unless overridden
    if [ "${params.keepRawGam}" != "true" ]
        then
            rm ${meta.read_group}.gam
    fi

    # Report filtered mapping statistics
    vg stats --alignments ${meta.read_group}.filtered.gam ${gbz} > ${meta.read_group}.filtered.gam.vg-stats

    # Get alignment count (to branch passed/failed samples)
    ALIGNMENT_COUNT=\$(grep "Total alignments:" ${meta.read_group}.filtered.gam.vg-stats | awk '{print \$3}')
    ${cleanup}
    """
}
