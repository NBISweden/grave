# Changelog


## [1.3.1] -

### Housekeeping

- Updated dag that was supposed to be in last release
- Merged PR #4 (fastqc module now allows for `fq.gz` or `fastq.gz` extensions)

### Software updates

- `pixi.toml 1.1` Apptainer: 1.3.6 -> 1.4.1
- `pixi.toml 1.1` nextflow: 24.10.4 -> 25.04.6
	- Nextflow update required syntax change for publishing outputs in `main.nf` + removal of topic feature flag in `grave.nf`. Small tweaks made to initialise subworkflow & README.md to reflect update
- `pixi.toml 1.1` vg: 1.63.0 -> 1.67.0 (updated bioconda recipe)

- Module containers: vg version to 1.67.0 in containers

### Configs

- Moved params to `nextflow.config` following nf-core best practices
- Same for base profiles. This means there is now an `apptainer` profile, replacing `containers.config`. Other base profiles added are debug and singularity. `README.md` updated to reflect this

### Documentation

- Extra guidance/background on `pixi` usage, general improvements

### Pipeline debugging/tracing

- Added `--tracing` parameter to enable comprehensive reports for the workflow, including timeline, report, trace, and dag files (stored in `${projectDir}/tracing`). Off by default.

### Bug fixes

`FASTQ_MERGE_DEDUP`: fixed potential issue that would arise if sample names contain ".", and generally cleaned the library count variables

`FASTQ_MERGE_DEDUP`: fixed bug for modern samples with multiple libraries (only first library was taken due to syntax error)


## [1.3.0] - 2025-08-18

### Added

- README.md updated with workflow output details and more information on genotyping and variant calling tools
- Most relevant, now explicitly point out the difference between the genotyping and variant calling tools

- Implemented `storeDir` for outputs that need to be run once (snarls, hapl index, filter index). This is helpful when multiple users share a file system for storing graphs. Processes won't rerun even on fresh repo clones
- These now store to a new folder next to the graph based on the graph basename, e.g.: `human.gbz`, indexes are stored in: `human_indexes`
- To ensure other stored indexes are not picked up by other stores, each index category goes into a specific subdirectory
- Linked to adding `storeDir`, temporarily disabled topic channel version reporting from 3 modules that use it (https://github.com/nextflow-io/nextflow/issues/5785)

- Linear references extracted from the graph are now included as output files in `results/linear_references`

- ext.args template added to each module, and placeholder module config file added `conf/modules.config`

- changed names of genotyping modules, channels, params etc. to increase their descriptive clarity - e.g. vg-graph-call -> vg_deconstruct, vg-map-call -> vg_genotype
- for clarity genotyping outputs go into a genotyping folder, not variant_calling

- output directory structure improved to reduce nesting, as a result of related changes to outputs

- module names use consistent underscore separation, more descriptive

- GAM filtering: added a param "--gamFilterMore". When false, filters only on primary alignment score + defrays ends. When true, applies MAPQ filter and discards unmapped reads
- Under the hood this is controlled by conditional logic in `modules.config` that sets the value of `ext.args2`

- Fastp previously defaulted to discard unmerged reads for aDNA samples. It now defaults to keeping them.
- This is controlled by a parameter `--discardUnmerged` (default false)
- Under the hood this controls FASTP `ext.args` in `modules.config`, outputting two extra fastq files for unmerged reads.
- If these files are present, they are first concatenated with the respective merged reads before sample level concatenation and re-deduplication
- i.e. the mapper would receiving one file per sample, containing all libraries, and both merged and unmerged reads in a single deduplicated package
- As a result of this change, also added safety to FASTQC on receiving empty FASTQ files

- Patched non-zero exit when getting heap space for profilepmd, which would cause process to fail even if successful. Force 0 exit.
- All output folders use underscores (no dashes) for consistency

- updated DAG

- additional test graphs added to `data/test/additional_graphs`

- added safety to FASTQC in case of empty input files (e.g. in the case of unmerged aDNA output from FASTP)



## [1.2.2] - 2025-03-04

### Fixed/added

- Patch to profiles, add cluster resource limits to prevent SLURM rejections on retry attempts

## [1.2.1] - 2025-03-04

### Fixed

- Patched profilepmd heap space issues, dynamically get maximum heap space and provide to profilepmd as upper limit

## [1.2.0] - 2025-02-28

### Changed

- Migrated to codespaces from gitpod

## [1.1.0] - 2025-02-26

### Added

- pixi environments, accounting for systems with custom Apptainer installations (e.g. systems where user namespace is not allowed). `default` lacks apptainer and will look for system-wide Apptainer, `apptainer` provides Apptainer support in the pixi environment

- option to skip profile pmd process

### Changed

- Batch submission shell script accounts for older tmux versions & other minor improvements

- Safety added to projectDir cleanup shell script

### Fixed

- addressed java heap space for `PROFILEPMD`

## [1.0.0] - 2025-02-19

### Added

- Initial grave release

### Dependencies

- pixi
