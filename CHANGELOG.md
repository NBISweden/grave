# Changelog

## [2.2.0] - Unreleased

### TODO: GAM filtering defaults

- Set defaults based on benchmarking:
    - set GAM filtering mapq to 20, which achieves a reasonable balance between yield and error
    - recommended settings would range from 20 to 30. Below 20 error becomes too high, above 30 or even 25, error is already so low that you are throwing away accurate alignments (and a lot of them)
    - turned off default identity filtering (since it's an untested filter)

### TODO Further improvement of k + w default

- Full benchmarking showed `15 + 5` performed better for short reads (30-50), and had no cost above this. Until even more options have been tested, this is the best balance yet.

### Grave now publishes library level BAMs

- previously we published: per-library filtered GAMs, per-library raw GAMs (if requested), and per-sample merged/deduplicated BAMs
- We now also publish the per-library BAMs (`graph mode` = surjected, RG tagged, mapped only, sorted. `linear mode` = RG tagged, mapped only, sorted)
- This adds utility for debugging library issues & also for benchmarking tasks that run only up to alignment

### Stats on the raw GAM

- Now optional via param `rawMapStats`

### Unmapped reads in graph modes & correcting surjection stats

- If users request the GAM to be filtered for mapped only, we previously filtered the library-level GAM only (i.e. remove unmapped relative to the graph)

- If that GAM goes on to be surjected to the linear backbone, some reads can become unmapped during that process (i.e. relative to linear coordinates)

- Now, if users ask to filter the GAM for mapped reads only, we also implicitly pass this through to the post-surjection BAM processing (samtools add readgroups, `view --exclude-flags 4`, sort. If they don't request GAM filtering, no filter is applied to the BAM either

- The other implication is that GAM alignment stats alone were misleading, since not all those filtered alignments survive surjection. We now also run flagstats on the surjected and processed BAM

### Stats on the final merged BAMs

- Added stats for the final merged BAMs

### Output publishing tweaks

- Due to all the additional stats reporting, reorganised the publishing directories for clarity
- Also cleaned up some of the stats file names to be more informative

### nf-core tools

- Bumped to v4.0.2 in pixi env

## [2.2.0-pre] (pre-release) 2026-05-28

### Benchmarking in 2.2.0-pre-release (41b9783)

- Benchmarking of mapping accuracy to be done in 2.2.0-pre-release `41b9783` (though note there will be 1 or more commits for benchmarking related files - no code changes)

### GAM filtering defaults

- [Prelease]: running benchmarks

### Logo

- added repo logo

### Developer guidance

- added guidance to any module with resources specifically set outside of `conf/base.config`

### Containers

- updated vg containers to 1.73

### Pixi environment

- vg bumped to 1.73.0 & lock file updated

### Giraffe aDNA scoring parameters

- Now implemented as parameters rather than hard-coded, though the settings are currently not changed

### Giraffe resources

- testing shows Giraffe runtime scales well with cpu count. Increased default to 64 cores.

### Graph indexing

- K-mer and window size default parameters should now work better for typical degraded aDNA reads (k 19, w 5 selected as a balanced default with excellent performance particularly at 50 & 70 bp, plus acceptable performance at 30)

- Notes added to nextflow.config regarding successful mapping of ultra-short reads

- added README explainer on k and w choice in the context of aDNA alignment, with examples of performance for target read lengths (e.g. k 15, w 5, if 30 bp performance needs to be improved)

- Changed the minimiser and zipcode extensions throughout the codebase to conform with those currently used by vg developers. (i.e. minimiser = `.withzip.min`, and zipcodes = `.zipcodes`)

- updated schema with selected defaults

### GAM filtering defaults

- [Prelease]: running benchmarks, [release], set defaults

### Prioritise filtered graphs

- Although unfiltered graphs + haplo mode are "best practices" in typical use cases, for `grave` the intended use case is aDNA. Samples will be highly contaminated & the target reads are both short & degraded. Thus we expect k-mer subsampling of the graph to perform worse than a depth filtered graph reference. Thus:

    - Updated basic tests to prioritise filtered graphs

    - Updated docs to reflect latest advice

    - Updated wiki to reflect latest advice

### Reference stats reporting processes are now optional

- added the `reference_stats` parameter to make reference stats reporting processes optional. Prior to the change, running the `index` step in isolation still forced stats reporting, which can a) take a long time & b) is not what the user requested

### vg stats resources

- changed resources label (low to medium) to avoid OOM errors for larger graphs

### Read QC file naming

- Now renames input files to raw FASTQC processing. Before, the pre/post FASTP reports needed to be cross-referenced if input FASTQ files were not named by sample. Now, they will share exactly the same sample/read group prefix for quick navigation.

### Added a giraffe alignment stats report

- added new stats report prior to alignment filtering, to quickly diagnose where issues might be occuring if low counts are observed, i.e., a) at entry into alignment, or b) at filtering after alignment

### Added ovis test resources for internal usage

- requires local graphs/linear reference, not uploaded to the repo due to size

## [2.1.0] - 20260309

### Updated

#### HPC resource requests
- Significant improvements to the default resource requests when running on HPC. More scale tests will be needed to finalise these

#### GAM filtering
- Removed all hard coded GAM filtering choices to args (added switch params for each of these, with a setting param for fine-tuning)
- Unmapped GAM records are now discarded by default (mirrors linear workflow)

#### Versions
- pixi env nf-core version to 3.5.2

#### Reference + index map simplified
- Removed complex logic for assigning index elements to the map. Now use a slice operation which allows for variable file counts

### Added

1. Parameter for FASTP minimum overlap for merge. Previously used program default of 30, which may have penalised our target fragment group. Set default to 11 to match AdapterRemoval (used by EAGER), + flash, used elsewhere.

2. New test profile & dataset for reads 20-40 bp

3. New logic to handle failed samples. Failed samples are those that have zero aligned reads after GAM filtering. Giraffe now exports the alignment count as an env variable, and the resulting channel is branched (0 = fail, >0 = pass). Previously these would pass to the next process and `grave` would crash. 

The failed samples can now be seen in the results folder: `04_mapped_reads/failed_samples`

### Fixed

#### Freebayes memory issues

- The current regions calculation for Freebayes parallel uses extortionate memory and needs to be refactored. In the meantime, added a freebayes mode option, such that by default Freebayes will run in single-threaded mode. This has been tested and finishes using appropriate resource allocation. An issue has been raised to eventually address the parallel mode.

#### Linear indexing
- Fixed issue whereby accession versions were stripped from the linear reference index `storeDir` directory. This would have caused issues if users ran grave on two versions of the same reference

#### Indexing + haplotype subsampling params simplified
- We had 8 confusingly named parameters where 4 would suffice. This is implemented, and names are more clear. 
- This additionally fixed a potential mapping issue if users changed the `aDNAkmerHaplSubSam` kmer value without mirroring the change in `aDNAKmerMimizer`. This scenario can now be safely handled by a single parameter change.

#### Confirmed zipcodes issue for aDNA samples
- Recent versions of vg create zipcodes files. If not found during giraffe runs, it auto creates new files with default params, which caused mapping failure for aDNA. This is fixed, with zipcode creation and provision now explicit

#### Potential mapping parameter issue for modern samples
- For modern DNA we previously allowed Giraffe to run auto-index construction (i.e. default kmer/window params), and controlled it for aDNA. This would cause problems if users adjusted these settings during `.hapl` construction
- Grave now controls index construction for both sample types for increased reliability

#### Linear workflow bug
- the BWA aln algorithm can output unmapped records with MAPQ > 0, which is incompatible with strict SAM specs enforced by picard. We now pipe from `samse/mem` into `samtools view`, and remove unmapped records prior to `samtools sort`


## [2.0.1] - 20260202

### Added

- nf-test functionality for main run modes

### Fixed

- multi-ref mode now functional again


## [2.0.0] - 20260130

### Key version updates

- Nextflow to 25.10.0
- vg to 1.70.0
- apptainer to 1.4.5 (apptainer env only)

### Added

- Linear mode to run mapping with traditional methods against a linear FASTA
- Workflow parameter validation & help message via nf-schema + custom function (removed existing custom validation & help)
- Docker support + other containerisation engines
- Future modules to be initiated with `nf-core modules install`, then patched
- All modules can now report versions (storeDir modules previously excluded, now require manual version update)

### Changed

- Reorganised repository structure, especially data, modules, and subworkflows
- Improved SLURM helper script, now in `bin`
- General code cleanup
- Some process names changed for clarity

### Refactored

#### Pixi environment

- Updated to version 2 environment
- Tasks overhauled for testing

#### Workflow

- replaced `grave` workflow with subworkflows
- `main.nf` now used to call distinct subworkflows, improving readability/maintainability/extensibility
- Added a linear mapping workflow option

#### Parameters

- Workflow can now run user-defined steps within the workflow (though some have step dependencies)

### Containers

- Various version updates to process containers

### Profiles

- Removed custom profiles, replaced with an nf-core style approach (base, resource, & institutional profiles) + test profile

## [1.4.1] - 20251007

### Bug fix

- Fixed missing `args3` in pangenome map module

### Parameters

- Tweaked default minimum allele support to allow leniency for aDNA (matches EAGER)

### Others

- Small fixes to docs
- Added threads flag to samtools index
- Minor annotation changes
- Removed old `--max-fragment-length` argument in ancient DNA mapping script blocks - these will always be "single ended" at the mapping stage.

### Wiki

- Wiki boilerplate pushed

## [1.4.0] - 20251006

### Reorganisation & documentation

- Params sections in `nextflow.config` clarified
- Corresponding help message sections have been clarified, and help messages improved for some parameters
- New dag
- Updated samplesheet info in README

### FASTP

- exact hash deduplication now defaults to off, controlled with `--fastpDedup`
- new parameter to control whether FASTP performs duplicate removal or not (even if turned off we get a rough duplication rate calculation)
- json report now also published alongside html
- improved help message on FASTP duplicate rate/removal params
- keeping unmerged reads now outputs these alongside the merged, rather than into two extra files

### FASTQC 

- removed empty file check (unmerged reads used to cause this but are output into the merged readfile now)
- html output
- improved syntax for other file extensions

### Deduplication overhaul

- Changed samplesheet metadata requirements (library_id and repeat_number: together with sample id, we can now generate a unique read group identifier)
- Removed all hash deduplication steps
- Mapping now done at the library level
- Surject now followed by readgroup annotation, sorting, BAM merging, and deduplication with Picard
	- New deduplication metrics file in `results/statistics`
	- `--removeDuplicates` (default `true`): If true, Picard MarkDuplicates will not write duplicate reads to the output. If false, they will be written, with duplicate flags set (true/false).
	- `--duplicateTaggingPolicy` (default `DontTag`): Policy for tagging duplicates in the DT optional SAM/BAM field (`DontTag`, `OpticalOnly`, `All`). Irrelevant if `--removeDuplicates` is true. See Picard docs for more info.
	- `--dedupConsiderBothEnds` (default `true`): If true, for appropriate samples Picard MarkDuplicates will consider both 5' and 3' ends of reads when identifying duplicates. If false, only the 5' end will be considered (true/false). Appropriate samples are "single ended reads" with both ends known, i.e. successfully merged aDNA reads.
- Picard settings allow for ancient DNA to use 3' and 5' information when identifying duplicates, mimicing `dedup` behaviour
- Since GAMs are split, implemented new merging logic for GAMs prior to `vg call`

### Removed

- `deconstructNestedSnarls` - this was a bugged parameter, removed to avoid confusion for now.

### Pangenome map filter

- Defraying of ambiguously aligned read ends is now turned off by default.
	- To turn it on, use `--gamDefrayEnds`
	- To control the maximum length of defray, use `--defrayEndsLength` (default 999)
- MAPQ filter is now on by default (default 30)
	- Control it with `--gamFilterMapQ`
	- Threshold set by `--minimumMapQFilter`


### DeepVariant

- Updated module to use pangenome aware version, updated code and output processing accordingly


## [1.3.4] - 20250912

### Parameter updates

- Replaced `--gamFilterMore` with two parameters:
	- `--gamDiscardUnmapped` (default false): when true, unmapped reads are discarded when filtering GAM files
	- `--gamFilterMapQ` (default false): when true, applies MAPQ filtering when processing GAM files. Threshold value is set by `--minimumMapQFilter`

- Changed default for `--minimumScorePrimaryAlign` from 0.90 to 0.80, to be more inclusive of aDNA reads with potentially lower fraction identity

- Added `--deconstructNestedSnarls` parameter. When false, vg deconstruct outputs only top-level sites (non-nested sites). Setting to true provides `--all-snarls` to vg deconstruct, which will output a site for all snarls spanned by a reference path.
	- Note: incomplete feature! Currently setting the default to `true`, and raised GitHub issue for further development. To get this working, will need to move `vcfbub` to a new module. Setting to false results in no LV tag in the output VCF, causing a vcfbub error.

### Documentation

- Started wiki on the repo for adding rationale to complex sections + explanation of behaviour

- Improvements to help message

### Profile improvements

- Added options to go directly to nf-core profiles for rackham and dardel rather than the custom ones

- Re-enabled scratch space in rackhamSlurm profile, draft fix on the bind mount issue

## [1.3.3] - 20250901

### Bug fixes

- Fastq merge dedup had a bug whereby it expected library names as integers. Old approach accounted for this with an awk + read line operation
- Replaced by providing the library names within the metamap as a new flattened list, and using these instead

- Temporarily commented out sections applying scratch space in HPC profiles. Running into an issue I haven't yet diagnosed -> causes file not found errors. This is since the Nextflow version bump.

## [1.3.2] - 20250829

### Housekeeping

- Cleaned up variable syntax for clarity and consistency
- Ensure no memory issues on laptops for `pixi run test` (hash based deduplication memory can spike on FASTP)
- Aligned index kmer sizes in params.
- Converted slurm example script to a pipeline agnostic template

### Vg command updates

- For complex graphs, `vg index` may cause memory issues. Users can switch on `--noNestedDistance` to add this option to the initial vg indexing commands and produce a limited version of the distance index. Note this currently wouldn't help for the pangenome-map module, in which case we'd consider upgrading that module to a `process_high` label

- `vg filter` - removed unused `ext.args`

## [1.3.1] - 20250819

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
