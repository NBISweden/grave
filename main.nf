#!/usr/bin/env nextflow

// Workflow initialisation
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_grave/main'
// Reference file utilities
include { REFERENCE_UTILITIES     } from './subworkflows/local/utils_reference/main'
// Read preproceesing and QC
include { PREPROCESS_READS        } from './subworkflows/local/01_preprocess_reads/main'
// Map
include { ALIGN_READS             } from './subworkflows/local/02_align_reads/main'
// Merge BAMs
include { MERGE_BAMS              } from './subworkflows/local/03_merge_bams/main'
// Deduplicate BAMs
include { DEDUPLICATE_BAM         } from './subworkflows/local/04_deduplicate_bam/main'
// Damage profiling
include { PROFILE_PMD             } from './subworkflows/local/05_profile_pmd/main'
// Genotyping
include { GENOTYPE                } from './subworkflows/local/06_genotype/main'
// Variant calling
include { VARIANT_CALL            } from './subworkflows/local/07_variant_call/main'

// Entry workflow
workflow {

    main:
    // Validate input parameters and create input file channels
    PIPELINE_INITIALISATION (
        params.version,         // boolean: Display version and exit
        params.validate_params, // boolean: Boolean whether to validate parameters against the schema at runtime
        params.monochrome_logs, // boolean: Do not use coloured log outputs
        args,                   //   array: List of positional nextflow CLI args
        params.outdir,          //  string: The output directory where the results will be saved
        params.input,           //  string: Path to input samplesheet
        params.help,            // boolean: Display help message and exit
        params.help_full,       // boolean: Show the full help message
        params.show_hidden      // boolean: Show hidden parameters in the help message
    )
    reference    = PIPELINE_INITIALISATION.out.reference
    samplesheet  = PIPELINE_INITIALISATION.out.samplesheet
    sample_types = PIPELINE_INITIALISATION.out.types
    paths        = params.multiple_references ? channel.fromPath("${params.paths_dir}/*.paths").collect() : [] // Set up paths channel if multi-reference mode

    // Parse requested workflow steps
    workflow_steps = params.steps.tokenize(",")

    // Run any required utility processes on the reference file
    REFERENCE_UTILITIES (
        workflow_steps,
        params.reference_type,
        params.reference_stats,
        reference,
        sample_types,
        paths
    )
    indexed_reference = REFERENCE_UTILITIES.out.indexed_reference   // Stored output
    stats             = REFERENCE_UTILITIES.out.stats
    reference_fastas  = REFERENCE_UTILITIES.out.reference_fastas
    snarls            = REFERENCE_UTILITIES.out.snarls              // Stored output

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // ~~~~~~ Main grave workflow ~~~~~~
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // Prepare reads (quality filtering + QC reports)
    fastp_reads         = channel.empty()
    fastp_report        = channel.empty()
    raw_fastqc_report   = channel.empty()
    fastp_fastqc_report = channel.empty()
    if ( 'preprocess' in workflow_steps) {
        PREPROCESS_READS (
            samplesheet
        )
        fastp_reads         = PREPROCESS_READS.out.fastp_reads
        fastp_report        = PREPROCESS_READS.out.fastp_report
        raw_fastqc_report   = PREPROCESS_READS.out.raw_fastqc_report
        fastp_fastqc_report = PREPROCESS_READS.out.fastp_fastqc_report
    }

    // Align reads (GAM + BAM produced in graph mode, & BAM in linear). Also adds read groups and sorts BAMs
    mapped_gam       = channel.empty()
    failed_libraries = channel.empty()
    raw_gam          = channel.empty()
    alignment_stats  = channel.empty()
    mapped_bam       = channel.empty()
    if ( 'align' in workflow_steps ) {
        ALIGN_READS (
            params.gpu_giraffe,
            params.reference_type,
            paths,
            fastp_reads,
            reference,
            indexed_reference
        )
        mapped_gam       = ALIGN_READS.out.mapped_gam
        failed_libraries = ALIGN_READS.out.failed_libraries
        raw_gam          = ALIGN_READS.out.raw_gam
        alignment_stats  = ALIGN_READS.out.alignment_stats
        mapped_bam       = ALIGN_READS.out.mapped_bam
    }

    // Merge library-level BAMs to sample-level for downstream analysis
    merged_bams = channel.empty()
    if ( 'merge' in workflow_steps ) {
        MERGE_BAMS (
            paths,
            mapped_bam
        )
        merged_bams = MERGE_BAMS.out.merged_bams
    }

    // Deduplicate sample-level BAMs
    deduplicated_bams     = channel.empty()
    deduplication_metrics = channel.empty()
    dedup_flagstats       = channel.empty()
    if ( 'deduplicate' in workflow_steps ) {
        DEDUPLICATE_BAM (
            paths,
            merged_bams
        )
        deduplicated_bams     = DEDUPLICATE_BAM.out.deduplicated_bams
        deduplication_metrics = DEDUPLICATE_BAM.out.deduplication_metrics
        dedup_flagstats       = DEDUPLICATE_BAM.out.dedup_flagstats
    }

    // Damage profile ancient samples if they are present
    damage_profiler = channel.empty()
    if ( 'profile_pmd' in workflow_steps ) {
        if ( sample_types != "modern" ) {
            PROFILE_PMD (
                paths,
                reference_fastas,
                deduplicated_bams
            )
            damage_profiler = PROFILE_PMD.out.damage_profiler
        }
    }

    // Genotyping
    graph_filtered_vcf = channel.empty()
    graph_raw_vcf      = channel.empty()
    reads_filtered_vcf = channel.empty()
    reads_raw_vcf      = channel.empty()
    if ( 'graph_genotype' in workflow_steps || 'reads_genotype' in workflow_steps ) {
        if ( params.reference_type != 'linear' ) {
            GENOTYPE (
                workflow_steps,
                reference,
                snarls,
                paths,
                reference_fastas,
                mapped_gam
            )
            graph_filtered_vcf = GENOTYPE.out.graph_filtered_vcf
            graph_raw_vcf      = GENOTYPE.out.graph_raw_vcf
            reads_filtered_vcf = GENOTYPE.out.reads_filtered_vcf
            reads_raw_vcf      = GENOTYPE.out.reads_raw_vcf
        }
    }

    // Variant calling
    freebayes_normalised_vcf   = channel.empty()
    freebayes_raw_vcf          = channel.empty()
    deepvariant_normalised_vcf = channel.empty()
    deepvariant_raw_vcf        = channel.empty()
    deepvariant_html           = channel.empty()
    if ( 'variant_call' in workflow_steps ) {
        VARIANT_CALL (
            params.freebayes,
            params.freebayes_mode,
            params.deepvariant,
            params.reference_type,
            reference,
            paths,
            reference_fastas,
            deduplicated_bams
        )
        freebayes_normalised_vcf   = VARIANT_CALL.out.freebayes_normalised_vcf
        freebayes_raw_vcf          = VARIANT_CALL.out.freebayes_raw_vcf
        deepvariant_normalised_vcf = VARIANT_CALL.out.deepvariant_normalised_vcf
        deepvariant_raw_vcf        = VARIANT_CALL.out.deepvariant_raw_vcf
        deepvariant_html           = VARIANT_CALL.out.deepvariant_html
    }

    // Report package versions
    channel.topic('versions')
        .map { process, tool, version ->
            return [process: process, tool: tool, version: version]
        }
        .unique()
        .collect()
        .map { it -> it.join('\n') }
        .collectFile(name: "${params.trace_timestamp}_package_versions.txt", newLine: true)
        .set { versions }

    // Define publish targets
    publish:
    // REFERENCE_UTILITIES
    stats                      = stats
    linear_references          = reference_fastas
    // PREPROCESS_READS
    fastp_report               = fastp_report
    raw_fastqc_report          = raw_fastqc_report
    fastp_fastqc_report        = fastp_fastqc_report
    // ALIGN_READS
    mapped_gam                 = mapped_gam
    failed_libraries           = failed_libraries
    raw_gam                    = raw_gam
    alignment_stats            = alignment_stats
    mapped_bam                 = mapped_bam
    // DEDUPLICATE_BAM
    deduplicated_bams          = deduplicated_bams
    deduplication_metrics      = deduplication_metrics
    dedup_flagstats            = dedup_flagstats
    // PROFILE_PMD
    damage_profiler            = damage_profiler
    // GENOTYPE
    graph_filtered_vcf         = graph_filtered_vcf
    graph_raw_vcf              = graph_raw_vcf
    reads_filtered_vcf         = reads_filtered_vcf
    reads_raw_vcf              = reads_raw_vcf
    // VARIANT_CALL
    freebayes_normalised_vcf   = freebayes_normalised_vcf
    freebayes_raw_vcf          = freebayes_raw_vcf
    deepvariant_normalised_vcf = deepvariant_normalised_vcf
    deepvariant_raw_vcf        = deepvariant_raw_vcf
    deepvariant_html           = deepvariant_html
    // Version reporting
    versions                   = versions

}

// Publish outputs
output {

    // Version reporting
    versions {
        path '01_pipeline_info/package_versions'
    }
    // REFERENCE_UTILITIES
    stats {
        path '02_reference/statistics'
    }
    linear_references {
        path '02_reference/extracted_linear_reference'
    }
    // PREPROCESS_READS
    fastp_report {
        path '03_read_qc/fastp_reports'
    }
    raw_fastqc_report {
        path '03_read_qc/raw_data_fastq_reports'
    }
    fastp_fastqc_report {
        path '03_read_qc/qced_data_fastq_reports'
    }
    // ALIGN_READS
    mapped_gam {
        path '04_mapped_reads/library/gams'
    }
    mapped_bam {
        path '04_mapped_reads/library/bams'
    }
    failed_libraries {
        path '04_mapped_reads/library/failed'
    }
    raw_gam {
        path '04_mapped_reads/library/raw_gams'
        enabled params.keepRawGam
    }
    alignment_stats {
        path '04_mapped_reads/library/alignment_statistics'
    }
    // DEDUPLICATE_BAM
    deduplicated_bams {
        path '04_mapped_reads/sample/bams'
    }
    deduplication_metrics {
        path '04_mapped_reads/sample/deduplication_statistics'
    }
    dedup_flagstats {
        path '04_mapped_reads/sample/bams_statistics'
    }
    // PROFILE_PMD
    damage_profiler {
        path '05_post_mortem_damage/damage_profiler'
    }
    // GENOTYPE
    graph_filtered_vcf {
        path '06_genotyping/graph'
    }
    graph_raw_vcf {
        path '06_genotyping/graph'
        enabled params.keepRawVcf
    }
    reads_filtered_vcf {
        path '06_genotyping/reads'
    }
    reads_raw_vcf {
        path '06_genotyping/reads'
        enabled params.keepRawVcf
    }
    // VARIANT_CALL
    freebayes_normalised_vcf {
        path '07_variant_calling/freebayes'
    }
    freebayes_raw_vcf {
        path '07_variant_calling/freebayes'
        enabled params.keepRawVcf
    }
    deepvariant_normalised_vcf {
        path '07_variant_calling/deepvariant'
    }
    deepvariant_raw_vcf {
        path '07_variant_calling/deepvariant'
        enabled params.keepRawVcf
    }
    deepvariant_html {
        path '07_variant_calling/deepvariant'
    }

}
