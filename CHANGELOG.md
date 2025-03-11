# Changelog

### Planned

- long read support

- deepvariant updates

- Reinstate support for topic channel version reporting in processes that use storeDir, see GH issue: https://github.com/nextflow-io/nextflow/issues/5785, currently disabled due to a Nextflow bug

___


## [Unreleased]

### Added

- README.md updated with workflow output details and more information on genotyping and variant calling tools
- Most relevant, now explicitly point out the difference between the genotyping and variant calling tools

### Added

- Implemented `storeDir` for outputs that need to be run once (snarls, hapl index, filter index). This is helpful when multiple users share a file system for storing graphs. Processes won't rerun even on fresh repo clones
- These now store to a new folder next to the graph using the graph basename, e.g.: `example-unfiltered.gbz`, indexes are stored in: `example-unfiltered_indexes`
- To ensure other stored indexes are not picked up by other stores, each index category goes into a specific subdirectory
- Linked to adding `storeDir`, temporarily disabled topic channel version reporting from 3 modules that use it (https://github.com/nextflow-io/nextflow/issues/5785)

### Added

- Linear references extracted from the graph are now included as output files in `results/linear_references`

### Added

- ext.args template added to each module, and placeholder module config file added `conf/modules.config`

### Changed

- changed names of genotyping modules, channels, params etc. to increase their descriptive clarity - e.g. vg-graph-call -> vg_deconstruct, vg-map-call -> vg_genotype
- for clarity genotyping outputs go into a genotyping folder, not variant_calling

### Changed

- output directory structure improved to reduce nesting, as a result of related changes to outputs

### Changed

- module names use consistent underscore separation, more descriptive

### Changed

- GAM filtering: no MAPQ filter, keep unmapped reads

### Fixed

- Patched non-zero exit when getting heap space for profilepmd, which would cause process to fail even if successful. Force 0 exit.
- All output folders use underscores (no dashes) for consistency


### Updated

- TODO: updated DAG









<!-- Release history -->

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
