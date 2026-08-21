process GET_TAXONOMY {

    label 'process_low'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/conifer_kraken2_pigz:92c988cd2082487c' :
        'community.wave.seqera.io/library/conifer_kraken2_pigz:975cbfd2e7372e9a' }"
    storeDir { "${params.database_store}" }

    output:
    path("taxonomy"), emit: ch_kraken2_taxonomy 

    script:
    """
    k2 download-taxonomy --db .
    """

}
