# Changelog

### Planned

- long read support

- deepvariant updates

___


## [Unreleased]




<!-- Release history -->

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
