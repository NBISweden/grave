include { FASTP                                } from '../../../modules/local/fastp/main'
include { FASTQC as QC_RAW; FASTQC as QC_FASTP } from '../../../modules/local/fastqc/main'

workflow PREPROCESS_READS {

    take:
    samplesheet

    main:
    // Run quality filtering on input reads
    FASTP(samplesheet)

    // Run FASTQC on raw reads
    QC_RAW(samplesheet)

    // Run FASTQC on filtered reads
    QC_FASTP(FASTP.out.ch_fastp_reads)

    emit:
    fastp_reads = FASTP.out.ch_fastp_reads
    fastp_report = FASTP.out.ch_fastp_report
    raw_fastqc_report = QC_RAW.out.ch_fastqc
    fastp_fastqc_report = QC_FASTP.out.ch_fastqc

}
