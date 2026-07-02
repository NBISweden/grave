include { GET_TAXONOMY } from '../../../modules/local/kraken2/get_taxonomy/main'
//include { KRAKEN2_BUILD } from '../../../modules/local/kraken2/build/main'
include { DOWNLOAD_DB  } from '../../../modules/local/download_db/main'

workflow PREFILTER_READS {

    take:
    fastp_reads
    prefiltering_tool
    build_db
    remote_database
    local_database

    main:
    filtered_reads = channel.empty()

    // Kraken2
    if ( prefiltering_tool == 'kraken2' ) {
        // Get database
        if ( build_db ) {
            // Get taxonomy files
            GET_TAXONOMY ()
            // Build Kraken2 database

            // KRAKEN2_BUILD (
            //     build_db
            // )
            // k2_database = KRAKEN2_BUILD.out.ch_kraken2_db
        } else if ( remote_database ) {
            DOWNLOAD_DB (
                remote_database
            )
            //k2_database = DOWNLOAD_DB.out.ch_kraken2_db
        } else {
            // Use local database
            k2_database = local_database
        }
        // Run analysis

        // handle memory-mapping for large databases



    } else if ( prefiltering_tool == 'centrifuge' ) {
        // Placeholder
    }

    //emit:
    //processed_reads = KRAKEN2.out.ch_filtered_reads

}
