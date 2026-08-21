process STANDARDISE_FASTA {

    tag "${fasta_file}"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.22.1--h96c455f_0' :
        'biocontainers/samtools:1.22.1--h96c455f_0' }"

    input:
    path fasta_file

    output:
    path "*.fasta", includeInputs: true

    script:
    def ext = fasta_file.getExtension()

    if (ext in ['fna', 'fa', 'fas'])
        """
        ln -s ${fasta_file} ${fasta_file.baseName}.fasta
        """

    else if (ext == 'fasta')
        """
        :
        """

}
