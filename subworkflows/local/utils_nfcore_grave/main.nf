// Initialise the nbisweden/grave pipeline
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { paramsHelp                } from 'plugin/nf-schema'
//include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
//include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:
    // Print version and exit if requested. Print pipeline parameters to JSON file.
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    // Validate parameters and generate help message to stdout
    // ~~~ DO NOT EDIT WHITESPACE BELOW ~~~
    before_text = """
    \033[0;92mnbisweden/grave ${workflow.manifest.version}\033[0m

    """
    after_text = """
    Log issues and questions at: \033[0;92m${workflow.manifest.homePage}/issues\033[0m
    """
    command = "pixi run nextflow main.nf -profile singularity,test"
    // ~~~ END OF FIXED WHITESPACE ~~~
    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command
    )

    // Custom validation for pipeline parameters (see function below)
    validateInputParameters()

    // Create channel from input samplesheet provided with params.input
    def uniqueReadGroups = new HashSet<String>() // Initialise empty set for detecting duplicate read groups
    ch_samplesheet = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true, skip: 0)
        .map { row ->
            // Populate metadata
            def meta = [
                id: row.sample_id,
                library: row.library_id,
                repeat: row.repeat_number,
                type: row.sample_type.toLowerCase(),
                merged: row.merged.toLowerCase()
            ]
            // Check no duplicate "read group" combinations
            def key = "${meta.id}${meta.library}${meta.repeat}"
            if (!uniqueReadGroups.add(key)) {
                error ("Error: found a duplicate for sample '${meta.id}' in the samplesheet. Each row should have a unique combination of 'sample_id', 'library_id' and 'repeat_number'.")
            }
            // Create read group meta field
            meta.read_group = "${meta.id}.${meta.library}.${meta.repeat}"
            // Check that merge information is true or false, convert to boolean
            if (!['true', 'false'].contains(meta.merged)) {
                error ("ERROR: Sample '${meta.id}' has an invalid 'merged' value: '${meta.merged}'. Please only supply 'true' or 'false' (case insensitive).")
            }
            meta.merged = meta.merged.toBoolean()
            // Check sample types are correctly stated
            if (!['ancient', 'modern'].contains(meta.type)) {
                error ("Error: for '${meta.read_group}' found the phrase '${meta.type}' in the samplesheet 'type' column, accepts 'ancient' or 'modern' (case insensitive).")
            }
            // Initial checks passed, add FASTQ paths
            if (meta.merged) {
                if (row.fastq_1 && !row.fastq_2) {
                    return [meta, [file(row.fastq_1)]]
                } else if (!row.fastq_1) {
                    error ("Error caused by sample: '${meta.read_group}'. No path to the merged FASTQ file is provided in column 'fastq_1'.")
                } else {
                    error ("Error caused by sample: '${meta.read_group}'. The workflow is expecting one merged FASTQ, but a second file was also provided.")
                }
            } else if (!meta.merged) {
                if (row.fastq_1 && row.fastq_2) {
                    return [meta, [file(row.fastq_1), file(row.fastq_2)]]
                } else {
                    error ("Error caused by sample: '${meta.read_group}'. The workflow is expecting two FASTQ files, received one or none.")
                }
            }
        }

    // Create reference channel
    ch_reference = channel.fromPath(params.reference, checkIfExists: true)

    // Create types channel for correct index generation (modern, ancient, or both)
    ch_types = ch_samplesheet
        .map { meta, _fastqs -> meta.type }
        .unique()
        .collect()
        .map { uniqueTypes ->
            uniqueTypes.size() == 1 ? uniqueTypes[0] : 'both' // If one type found, assign that type to "ch_types". Else assign "both".
        }

    emit:
    samplesheet = ch_samplesheet
    reference   = ch_reference
    types       = ch_types

}

// workflow PIPELINE_COMPLETION {

//     take:
//     outdir          //    path: Path to output directory where results will be published
//     monochrome_logs // boolean: Disable ANSI colour codes in log output

//     main:
//     summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

//     //
//     // Completion email and summary
//     //
//     workflow.onComplete {

//         completionSummary(monochrome_logs)
//     }

//     workflow.onError {
//         log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting"
//     }
// }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check and validate pipeline parameters
def validateInputParameters() {

    // Define valid workflow steps
    def permitted_steps = [
        'preprocess',     // read preprocessing
        'index',          // reference indexing
        'align',          // alignment to the reference
        'merge',          // merging of library-level BAMs to sample-level BAMs
        'deduplicate',    // deduplication of BAMs
        'graph_genotype', // genotyping on the graph alone
        'reads_genotype', // genotyping on mapped reads against the graph
        'variant_call',   // variant calling on surjected reads
        'assess_pmd'      // post-mortem damage profiling (ancient samples only)
    ]

    // Parse requested steps
    def requested_steps = params.steps.tokenize(",")
    // Check requested steps are valid
    def invalid_steps = requested_steps.findAll { step -> !(step in permitted_steps) }
    // Report invalid steps
    if ( invalid_steps ) {
        error "ERROR: Unrecognised workflow step(s) provided:\n - Permitted steps are: ${permitted_steps}\n - Invalid step(s): ${invalid_steps.join(', ')}"
    }
    // Define step dependencies
    def step_dependencies = [
        'preprocess'    : [], // no dependencies
        'index'         : [],
        'align'         : ['preprocess', 'index'],
        'merge'         : ['align'],
        'deduplicate'   : ['merge'],
        'graph_genotype': [],
        'reads_genotype': ['align'],
        'variant_call'  : ['deduplicate'],
        'assess_pmd'    : ['deduplicate']
    ]

    // Check step dependencies are met
    def missing_dependencies = []
    requested_steps.each { step ->
        def required_deps = step_dependencies[step]
        def missing = required_deps.findAll { dep -> !(dep in requested_steps) }
        if ( missing ) {
            missing_dependencies << "Step '${step}' is missing required dependencies: ${missing.join(', ')}."
        }
    }
    // Inform user of missing step dependencies
    if ( missing_dependencies ) {
        error "ERROR: An invalid combination of steps was requested.\n - You requested steps: ${requested_steps.join(', ')}\n - ${missing_dependencies.join('\n  - ')}\n"
    }




    // TODO Check incompatible reference with params. Check for missing params given the requested steps (reference not forced, but required for index)

    // // Check correct reference format provided for the selected reference type
    // if ( params.reference_type == 'graph' ) {
    //     params.reference

    // }



    // TODO fix below
    // // When running against a graph, ensure graph mode is set
    // if ( params.reference_type == 'graph' && ! params.graph_mode ) {
    //     error "ERROR: When using a graph reference, please also provide the graph mode (see --help)"
    // }

}

// Saved, currently unused features of nf-core template:

    // Check config provided to the pipeline
    // UTILS_NFCORE_PIPELINE (
    //     nextflow_cli_args
    // )
