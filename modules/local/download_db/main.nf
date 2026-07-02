process DOWNLOAD_DB {

    tag "${remote_database}" //TODO fix tag
    label 'process_medium'
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/aria2:1.37.0--6291571676811c24' :
        'community.wave.seqera.io/library/aria2:1.37.0--57ac2f4880f94ad1' }"
    storeDir { "${params.database_store}" }

    input:
    val remote_database

    //output
    //TODO output the final files to storedir, remove temp files. (untarred, ready to use db files)

    script:
    
    """
    TAR_FILE=\$(basename "${remote_database}")
    aria2c -d . -o "\$TAR_FILE" -x 16 -k 100M "${remote_database}"

    # Also read into aria2c option:  -s, --split=N                Download a file using N connections. 

    # handle md5
    # clean up unrequired downloads
    """

}
