process STANDARDISE_FASTA {

    tag "${fasta_file}"

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
