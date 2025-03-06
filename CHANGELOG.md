# Changelog

### Planned

- long read support

- deepvariant updates

- Reinstate support for topic channel version reporting in processes that use storeDir, see GH issue: https://github.com/nextflow-io/nextflow/issues/5785, currently disabled due to a Nextflow bug

___


## [Unreleased]

### Fixed

- Patched non-zero exit when getting heap space for profilepmd, which would cause process to fail even if successful. Force 0 exit.

### Added

- Implemented `storeDir` for several outputs that need to be run only once. This is helpful when multiple users share a file system hosting graphs for instance, as these outputs will be pulled from the store.

- Linked to adding `storeDir`, temporarily disabled all topic channel version reporting from modules that use it (https://github.com/nextflow-io/nextflow/issues/5785)



<!-- Release history -->

## [1.2.2] - 2025-03-04

### Fixed/added

- Patch to profiles, add cluster resource limits to prevent SLURM rejections

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
