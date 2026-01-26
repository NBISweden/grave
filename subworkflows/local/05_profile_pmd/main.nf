include { DAMAGE_PROFILER } from '../../../modules/local/damageprofiler/main'

workflow PROFILE_PMD {

    take:
    ch_paths
    reference_fastas
    deduplicated_bams

    main:
    // Run DamageProfiler to assess post-mortem damage patterns
    DAMAGE_PROFILER (
        ch_paths,
        reference_fastas,
        deduplicated_bams
    )

    emit:
    damage_profiler = DAMAGE_PROFILER.out.ch_pmd_profiles

}
