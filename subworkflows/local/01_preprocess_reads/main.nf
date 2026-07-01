include { FASTP           } from '../../../modules/local/fastp/main'
include { PREFILTER_READS } from '../../../subworkflows/local/01_preprocess_reads/filter'
include { RENAME_SAMPLES  } from '../../../modules/local/rename_samples/main'
include { FASTQC as QC_RAW; FASTQC as QC_FASTP; FASTQC as QC_FILTERED } from '../../../modules/local/fastqc/main'

workflow PREPROCESS_READS {

    take:
    samplesheet
    workflow_steps

    main:
    // Run quality filtering on input reads
    FASTP(samplesheet)
    processed_reads = FASTP.out.ch_fastp_reads

    // Run the prefiltering subworkflow if requested
    if ( 'prefilter' in workflow_steps) {
        PREFILTER_READS (
            processed_reads
        )
        processed_reads = PREFILTER_READS.out.ch_filtered_reads
    }

    // For raw FASTQ inputs, make links with the same naming style as FASTP output: FASTQC results more easily cross-referenced
    RENAME_SAMPLES(samplesheet)

    // Run FASTQC on raw reads
    QC_RAW(RENAME_SAMPLES.out.ch_renamed_reads)

    // Run FASTQC on FASTP processed reads
    QC_FASTP(FASTP.out.ch_fastp_reads)

    // Run FASTQC on prefiltered reads if requested
    filtered_fastqc_report = channel.empty()
    // if ( 'prefilter' in workflow_steps) {
    //     QC_FILTERED(PREFILTER_READS.out.ch_filtered_reads)
    //     filtered_fastqc_report = QC_FILTERED.out.ch_fastqc
    // }

    emit:
    processed_reads        = processed_reads
    fastp_report           = FASTP.out.ch_fastp_report
    raw_fastqc_report      = QC_RAW.out.ch_fastqc
    fastp_fastqc_report    = QC_FASTP.out.ch_fastqc
    filtered_fastqc_report = filtered_fastqc_report

}
