include { FREEBAYES           } from '../../../modules/nf-core/freebayes/main'
include { FREEBAYES_PARALLEL  } from '../../../modules/local/freebayes/main'
include { GRAPH_DEEPVARIANT   } from '../../../modules/local/deepvariant/main'
include { LINEAR_DEEPVARIANT  } from '../../../modules/local/deepvariant/linear'
include { PROCESS_DEEPVARIANT } from '../../../modules/local/deepvariant/process_vcf'

workflow VARIANT_CALL {
    take:
    freebayes
    freebayes_mode
    deepvariant
    reference_type
    reference
    paths
    reference_fastas
    deduplicated_bams

    main:
    freebayes_normalised_vcf   = channel.empty()
    freebayes_raw_vcf          = channel.empty()
    deepvariant_normalised_vcf = channel.empty()
    deepvariant_raw_vcf        = channel.empty()
    deepvariant_html           = channel.empty()

    // User info in case no variant caller was selected
    if ( !freebayes && !deepvariant ) {
        println "WARNING: the variant calling subworkflow was requested, but no variant caller combination was specified."
    }

    // FreeBayes variant calling
    if ( freebayes ) {
        if ( freebayes_mode == "single_thread" ) {
            FREEBAYES (
                paths,
                reference_fastas,
                deduplicated_bams
            )
            freebayes_normalised_vcf = FREEBAYES.out.ch_freebayes_norm_vcf
            freebayes_raw_vcf        = FREEBAYES.out.ch_freebayes_raw_vcf
        } else if ( freebayes_mode == "parallel" ) {
            FREEBAYES_PARALLEL (
                paths,
                reference_fastas,
                deduplicated_bams
            )
            freebayes_normalised_vcf = FREEBAYES_PARALLEL.out.ch_freebayes_norm_vcf
            freebayes_raw_vcf        = FREEBAYES_PARALLEL.out.ch_freebayes_raw_vcf
        }
    }

    // DeepVariant variant calling
    if ( deepvariant && reference_type != "linear" ) {
        GRAPH_DEEPVARIANT (
            reference,
            paths,
            reference_fastas,
            deduplicated_bams
        )
        deepvariant_html = GRAPH_DEEPVARIANT.out.ch_deepvariant_html
        PROCESS_DEEPVARIANT (
            paths,
            reference_fastas,
            GRAPH_DEEPVARIANT.out.ch_raw_deepvariant_vcf
        )
        deepvariant_normalised_vcf = PROCESS_DEEPVARIANT.out.ch_deepvariant_norm_vcf
        deepvariant_raw_vcf        = PROCESS_DEEPVARIANT.out.ch_deepvariant_raw_vcf
    } else if ( deepvariant && reference_type == "linear" ) {
        LINEAR_DEEPVARIANT (
            reference_fastas,
            deduplicated_bams
        )
        deepvariant_html = LINEAR_DEEPVARIANT.out.ch_deepvariant_html
        PROCESS_DEEPVARIANT (
            paths,
            reference_fastas,
            LINEAR_DEEPVARIANT.out.ch_raw_deepvariant_vcf
        )
        deepvariant_normalised_vcf = PROCESS_DEEPVARIANT.out.ch_deepvariant_norm_vcf
        deepvariant_raw_vcf        = PROCESS_DEEPVARIANT.out.ch_deepvariant_raw_vcf
    }

    emit:
    freebayes_normalised_vcf
    freebayes_raw_vcf
    deepvariant_normalised_vcf
    deepvariant_raw_vcf
    deepvariant_html

}
