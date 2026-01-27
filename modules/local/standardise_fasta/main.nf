process STANDARDISE_FASTA {

    tag "${fasta_file}"
    label 'process_single'

    input:
    path fasta_file

    output:
    path "*.fasta", includeInputs: true

    script:
    def ext = fasta_file.getExtension()

    if (ext in ['fna', 'fa', 'fas'])
        """
        ln -s ${fasta_file} ${fasta_file.simpleName}.fasta
        """

    else if (ext == 'fasta')
        """
        :
        """

}
