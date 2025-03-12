# Changelog

### Planned

- long read support
	- add metadata field
	- plug in long read variant callers

- deepvariant updates: now directly supports graphs
	- also see [here](https://ucsc-ci.com/comparativegenomicstoolkit/cactus/-/blob/2dd29514027a0ad2c1a5d0ab581c7930c943fac5/doc/sa_refgraph_hackathon_2023.md#part-3-mapping-reads-to-the-graph)
	- and [here](https://google.github.io/deepvariant/posts/2018-12-05-improved-non-human-variant-calling-using-species-specific-deepvariant-models/)

- Reinstate support for topic channel version reporting in processes that use storeDir, see GH issue: https://github.com/nextflow-io/nextflow/issues/5785, currently disabled due to a Nextflow bug

- Better test data with known variants of interest, add screenshots of variant calls vs genotyping outcomes

- Integrate an optional input of reference assembly annotation file(s), with built in liftover to the extracted references

- Support interleaved BAM input, convert to FASTQ (see EAGER)

- Joint freebayes calling, or post-hoc (multiVCFanalyzer?) (see EAGER). Check also freebayes implementation in EAGER.

- Check other EAGER modules

- Consider mapping quality assessment: preseq, qualimap2, endorS.py (EAGER)

- Consider other tools: MtNucRatio, GATK, bedtools, bamUtils, ANGSD, pileupcaller, VCF2Genome, MultiVCFAnalyzer, bcftools annotate, bcftools for genotyping/filtering, snpeff, vep, bamRefine
	- ANGSD: instead of using pileupCaller, could use ANGSE in two separate modules: pseudo-haploid genotyping and genotype likelihoods

- Consider VCF binning (e.g., HPRC deconstructs twice with different filters, also does joint calling? and then splits to sample level VCF)
	- HPRC: -l 0 -r 10000000, then separates into SVs and small variants
	- HPRC: -r 100000, keeping nested variants
	- Split multi-sample VCF to single with bcftools
	- Multiallelic sites split to bi-allelic records
	- VCF decomposed to SNPs and indels with vcfdecompose
	- Extract and normalise small variants with bcftools
	- Concatenate again on sample level
	- Similar with DeepVariant & then compare

- Potential flaw:
	- this approach assumes sample name will never be the same. But two haplotypes from the same sample will have the same sample name:
	`vg paths --paths-file \$i --extract-fasta -x ${graph} > \$basename.fasta`
	- add haplotype number metadata field and update metadata labelling within processes

______________________________________________________________________


## [Unreleased]





## [1.3.0] - 2025-03-XX TODO: [Unreleased]

### Added

- README.md updated with workflow output details and more information on genotyping and variant calling tools
- Most relevant, now explicitly point out the difference between the genotyping and variant calling tools
- TODO: detail on deepvariant and freebayes

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

- GAM filtering: added a param "--gamFilterMore". When false, filters only on primary alignment score + defrays ends. When true, applies MAPQ filter and discards unmapped reads
- Under the hood this is controlled by conditional logic in `modules.config` that sets the value of `ext.args2`

### Changed

- Fastp previously defaulted to discard unmerged reads for aDNA samples. It now defaults to keeping them.
- This is controlled by a parameter `--discardUnmerged` (default false)
- Under the hood this controls FASTP `ext.args` in `modules.config`, outputting two extra fastq files for unmerged reads.
- If these files are present, they are first concatenated with the respective merged reads before sample level concatenation and re-deduplication
- i.e. the mapper would receiving one file per sample, containing all libraries, and both merged and unmerged reads in a single deduplicated package
- As a result of this change, also added safety to FASTQC on receiving empty FASTQ files

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
