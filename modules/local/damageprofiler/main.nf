process PROFILE_PMD {

    tag "${meta.id}"
    label 'process_medium'
    container 'oras://community.wave.seqera.io/library/damageprofiler_vg:3a747afa19c19206'

    input:
    path ref_path_files
    tuple path(reference_fasta), path(fasta_index)
    tuple val(meta), path(bams), path(indexes)

    output:
    path "*_pmd", emit: ch_pmd_profiles
    tuple val(task.process), val('vg'), eval('vg version | head -n 1 | sed "s/vg version v//g; s/ .*//"'), topic: versions
    tuple val(task.process), val('damageprofiler'), eval('damageprofiler -version | sed "s/.* v//"'), topic: versions

    when:
    def args = task.ext.args ?: ''
    meta.type == 'ancient' && params.profilePMD == true

    script:
    if (!params.multiple_references)	// Assume single reference sample
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Run PMD profiling
        damageprofiler -Xms2g -Xmx\${MAX_HEAP_GB}g -i ${meta.id}.dedup.bam -r ${reference_fasta} -o ${meta.id}_pmd -t 20 -l 100 -yaxis_dp_max 0.3
        """

    else if (params.multiple_references)	// When multi ref samples, run damageprofiler on each specific pair
        """
        # Find system Java max heap size & convert to GB
        MAX_HEAP_BYTES=\$(java -XX:+PrintFlagsFinal 2>/dev/null | grep MaxHeapSize | grep -v Soft | awk '{print \$4}') || true
        MAX_HEAP_GB=\$(expr \$MAX_HEAP_BYTES / 1024 / 1024 / 1024)

        # Loop over each surjection target
        for i in *.paths
            do
                PREFIX=`echo \$i | sed 's/\\.paths//'`
                damageprofiler -Xms2g -Xmx\${MAX_HEAP_GB}g -i ${meta.id}.\$PREFIX.dedup.bam -r \$PREFIX.fasta -o ${meta.id}_surjected_to_\${PREFIX}_pmd -t 20 -l 100 -yaxis_dp_max 0.3
            done
        """

}
