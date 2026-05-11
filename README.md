[![Pixi Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)
![Nextflow](https://img.shields.io/badge/Nextflow-v25.10.2-brightgreen)

<p align="center">
  <img src="assets/grave.svg" alt="grave" width="500">
</p>

<div align="center"><strong>Graph Variant Explorer: Pangenomic analysis of ancient or modern DNA</strong></div><br>

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/NBISweden/grave)

## Brief description

`grave` is a Nextflow workflow for mapping, genotyping, and variant calling ancient or modern samples against a pangenome graph. A Wiki with a detailed summary of workflow steps is found [here](https://github.com/NBISweden/grave/wiki).

In normal use, the inputs to `grave` are a pangenome graph in `.gbz` format and a `.csv` samplesheet (listing either paired-end or pre-merged FASTQ data).

`NOTE:` To compare outcomes of graph-based versus traditional (linear assembly) workflow methodologies, `grave` can also be run in [linear mode](#linear-reference-mode) against a single FASTA reference instead of a graph.

Outputs are described [here](#workflow-outputs).

More information on genotyping and variant calling is found [here](#genotyping-and-variant-calling).

It is recommended to construct the graph with [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md). Before doing so, read this [section](#generate-or-provide-a-reference).

## Quick start

### Local or HPC installation

1. [Install Pixi](https://pixi.sh/latest/installation/): `curl -fsSL https://pixi.sh/install.sh | sh`
2. Clone the Workflow repository: `git clone https://github.com/NBISweden/grave.git`
3. Run `pixi install`

>[!NOTE]
>The pixi project contains two environments:<br><br>
>`default`: installed with `pixi install`. This lacks apptainer (e.g. for systems with an existing Apptainer installation).<br><br>
>`apptainer`: installed with `pixi install -e apptainer`. This provides an Apptainer installation.

<details>

<summary><h3>Information on pixi usage (drop down)</h3></summary>

- At minimum, `grave` can be run with `Nextflow` and either `Apptainer`, `Singularity`, or `Docker` installed in `$PATH`
- However, for reproducibility it is recommended to run it via `pixi`.
- `pixi` is a drop-in replacement for `conda`, and `grave` uses it to install its basic dependencies.
- `pixi` environments have an editable manifest file of direct dependencies, the `pixi.toml`
- Solved environments also have a `pixi.lock` file, which lists exact versions of all dependencies including transitive ones - the lockfile in this repository represents an environment that has been tested for Linux systems
- Installed `pixi` environments are found in the hidden folder `.pixi/envs`
- `pixi` will automatically install an environment it lacks, if implied by another command (e.g., `pixi run -e apptainer ...` would install the `apptainer` environment even if the `default` environment is the only one installed)
- You can run commands in a `pixi` environment by prefixing them with `pixi run` (or in a specific environment with `pixi run -e <environment>`)
- Alternatively you can shell inside an environment with `pixi shell` (or into a specific environment with `pixi shell -e <environment>`), similar to `conda activate <environment>` (at this point you no longer need the `pixi run` prefix)
- To delete an environment: `rm -rf .pixi/envs/<environment_name>`

</details>

### Run grave with the bundled test data

- To run with provided data using Apptainer: `pixi run test-apptainer`

- To run with provided data using Docker: `pixi run test-docker`

>[!TIP]
> All `pixi run` commands use the `default` environment. To specify the `apptainer` environment:<br><br>
>`pixi run -e apptainer test-apptainer`

### Running grave with your own data

### Step 1 of 2: Preparing the input files

#### Generate or provide a reference

- References can be in one of three types: `filtered_graph`, `unfiltered_graph`, or `linear` (i.e., FASTA alignment).

- Graphs must be provided in `.gbz` format, such as those produced by [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus). Because `grave` is designed to handle very short reads (i.e., aDNA at <50 bp) in addition to typical (100-150 bp) short reads, it recreates all graph indexes, and users do not need to supply them.

- When using `Minigraph-Cactus` for graph construction, please take note to keep contig names for the input FASTAs as simple as possible, [see the official guidance here](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#contig-names). Avoid hash characters in contig names!

- There are two main methods for building the graph with `Minigraph-Cactus`, see below:

##### Filtered graphs

- This method of building pangenome graphs for read mapping uses coverage filtering to remove nodes not found in a set number of haplotypes, typically this should be set to around 10% of the number of haplotypes (i.e., `40 haplotypes` in the graph: set depth to `4`).

- By default the `MiniGraph-Cactus` option `--giraffe` generates a graph filtered to depth 2. Coverage support level can be adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`

- The filtered graph (e.g., `graph.d10.gbz`) is used as input to `grave`, with the parameter `reference_type` set to `filtered_graph`

- The cost of this approach is that variants under the depth filter will be removed from the graph. This should be considered when users are building a graph from relatively divergent assemblies, or for example when a target organism with a single assembly is to be compared with related species. If users cannot afford to lose under-represented variant information they may prefer to use an unfiltered graph (see below).

> [!IMPORTANT]
> - Depth filtered graphs are not considered current best practice when users can provide relatively high coverage and high quality readsets typical of modern samples (e.g. 20x read coverage with 150 bp reads). In this case, an approach that uses *K*-mers from the reads to sample representative haplotypes from the unfiltered graph is preferable, `see unfiltered graphs section below`.
> - However, when running `short, highly degraded, and contaminated aDNA readsets` through `grave`, `filtered graphs may perform better`.
> - This is because haplotype subsampling of the graph using read *K*-mers is likely to underperform. Issues include the low coverage of target reads, deamination of target reads, short target reads (that require higher read coverage to perform comparibly with longer reads), and high representation of non-target *K*-mers. Depending on the use case, it may be preferable to sacrifice some rare variants and use a depth filtered graph, or at least test both graph types.

##### Unfiltered graphs

- Running in unfiltered graph mode utilises *K*-mer profiling of the reads to sample representative haplotypes from the graph for mapping, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling).

> [!IMPORTANT]
> See the above section, users should consider (or test) whether an unfiltered graph is appropriate for their samples.

- To build the graph, run `MiniGraph-Cactus` with option: `--haplo` (`--giraffe` is not required)

- The clipped, unfiltered graph (e.g., `graph.gbz`) is used as input to `grave`, with the parameter `reference_type` set to `unfiltered_graph`

#### Fill out the samplesheet

Complete a `samplesheet.csv` file, detailing file system paths to your reads. The layout is shown below.

>[!TIP]
> The table below is an example. The file provided to `grave` must be in `.csv` format

| sample_id     | library_id | repeat_number | sample_type | merged | fastq1                | fastq2               |
|---------------|------------|---------------|-------------|--------|-----------------------|----------------------|
| ancientHuman1 |      1     |      1        |   ancient   | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| ancientHuman1 |      1     |      2        |   ancient   | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| ancientHuman1 |      2     |      1        |   ancient   | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| modernHuman7  |      1     |      1        |   modern    | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| mergedInput   |      1     |      1        |   ancient   | true   | /path/to/merged.fq.gz |                      |

- `sample_id`: unique sample identifier

- `library_id`: unique library identifier

- `repeat_number`: repeat number of the library

- `sample_type`: sample is ancient or modern - **Note:** _this affects how the sample will be processed_

- `merged`: whether the reads have already been merged (e.g., some ancient samples)

- `fastq1`: relative or absolute path to the first FASTQ

- `fastq2`: relative or absolute path to the second FASTQ

#### Customise your run parameters

Run parameters can be set for `grave` by editing the `params.yml` file, and providing it on the command line when you execute the workflow. These will override the default parameters.

The only mandatory parameter is `--steps`, a string specifying which pipeline subworkflows to run, e.g., (`--steps 'index,preprocess'`). Each requested step has further dependencies which the user will be prompted to provide.

Use `pixi run help` to see the available parameters and their descriptions.

> [!IMPORTANT]
> The graph aligner `vg giraffe` uses a seed and extend strategy, with two important parameters: *K*-mer length (`k`) and window length (`w`).
> During graph indexing, minimisers are calculated from the graph, by sliding across length `w` and taking the sequence (minimiser) of length `k` with the smallest hash value.
> The seeding stage of alignment involves computing exact matches between these minimisers and reads.
> Users must keep in mind that reads shorter than `k+w-1` will not be aligned, as they cannot be seeded. <br><br>
> To address this, `grave` uses different `k` and `w` defaults for modern and ancient reads.
> Modern samples are run with the program defaults, emphasising higher specificity (`k` = 29, `w` = 11).
> For aDNA reads, which are usually short and highly degraded, achieving more exact matches to minimisers involves reducing specificity via a lower `k`.
> Meanwhile, minimiser density in the index can be boosted via lowering `w`.
> Reducing either of these values can increase alignment runtime. <br><br>
> The `grave` aDNA default settings (`k` = 19, `w` = 5) are selected to balance sensitivity/specificity with computational runtime.
> Users may find that adjusting these parameters for their particular use case can improve performance. <br><br>
> Suggested further reading: [Rubin et al., 2025, NAR Genomics and Bioinformatics](https://academic.oup.com/nargab/article/7/4/lqaf170/8376687).<br>
> As the authors note, there is no single best combination setting for `k` and `w` in the aDNA context, as it depends on several factors related to the graph and reads.

**Comparison of alignment parameters**<br>

| Alignment tool                 | \|---      | Percent aligned | ---\|    | \|---   | Runtime | ---\|   |
| :------:                       |  :-:       | :-----:         | :-:      | :--:    | :---:   | :--:    |
| *Read length*\*                | *30*       | *50*            | *70*     | *30*    | *50*    | *70*    |
| `grave`: `k-21, w-11`          | 0.0**      | 92.1            | 96.5     | 3m 44s  | 3m 54s  | 3m 33s  |
| `grave`: `k-19, w-5`           | 77.83      | **95.9**        | **97.6** | 3m 43s  | 4m 4s   | 4m      |
| `grave`: `k-17, w-9`           | 71.7       | 94.1            | 96.4     | 3m 30s  | 3m 34s  | 3m 44s  |
| `grave`: `k-15, w-7`           | 84.1       | 94.5            | 96.6     | 3m 44s  | 3m 33   | 3m 56s  |
| `grave`: `k-15, w-5`           | **89.7**   | 95.5            | 97.0     | 6m 43s  | 3m 43s  | 3m 52s  |
| `bwa aln: -l 16500 -n 0.01 -o 2`*** | 88.3  | 89.0            | 90.0     | 10.6s   | 28.5s   | 1m 5s   |

Unmapped reads removed, no additional `GAM/BAM` filtering, `grave` defaults for the remaining settings.<br>Note that `bwa` defaults to use 6 cpus, while `grave` uses 64.

\*~10k merged reads were generated (per length) with `NGSNGS` from a related assembly not present in the graph (sheep).

\*\*`k+w-1` (31) is greater than the read length (30), therefore no alignments are generated.

\*\*\*The bwa linear reference was the same assembly used as the graph backbone.

#### Was your graph built with more than one reference sample?

- `Minigraph-Cactus` requires at least one [reference sample](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#Reference-Sample), usually the most contiguous reference assembly, e.g.: `cactus-pangenome --reference GRCh38`

- If your graph has a single reference sample, you can skip this section.

- Paths through the reference sample are called _reference paths_. Unless configured otherwise, `grave` will assume __a single reference sample__, and use rational defaults that assume the same, for example `surject` will transform GAM alignments to linear BAM relative to __all reference paths__ in the graph. If there is more than one reference sample in the graph, this will cause undesirable outputs in certain steps, and errors in others

- Therefore, if your graph was built with multiple reference samples, e.g.: `cactus-pangenome --reference GRCh38 chimp gorilla`, it is required to run `grave` with `--multiple_references`, and to provide one or more `.paths` files

- Each `.paths` file contains a list of the reference paths in one reference sample, with one path name per line

- __The name of the `.paths` file matters__: the prefix must match a reference sample name provided in the `seqFile` of `Minigraph-Cactus`, and the suffix must be `.paths`, e.g.: `GRCh38.paths`, `chimp.paths`, and `gorilla.paths`

>[!TIP]
> `vg` is packaged in the pixi environment, to see the reference samples in your graph run: `pixi run vg paths --reference-paths --metadata -x myGraph.gbz | cut -f3 | tail -n+2 | sort | uniq`<br><br>
> For a list of all reference path names from, for example GRCh38, run: `pixi run vg paths --reference-paths --metadata -x myGraph.gbz | tail -n+2 | awk '$3 == "GRCh38"' | cut -f1 > GRCh38.paths`

- For each `.paths` file provided, `grave` will run pipeline steps relative to that sample separately from the others, e.g., `surject` will produce a separate `.bam` file per reference sample, such that surjecting `unknownSimian.1.gam` to `chimp.paths` and `gorilla.paths` will produce:

```
unknownSimian.1.chimp.bam
unknownSimian.1.gorilla.bam
```

### Step 2 of 2: Running grave

> Example of how to run a local test (not recommended for production runs)

`pixi run -e apptainer nextflow main.nf -profile apptainer,test -params-file params.yml`

> Running at scale (e.g., on SLURM cluster)

- Institutional profiles are available via `nf-core` for many major HPC centres, see [here](https://nf-co.re/configs/). The example command below configures `grave` for the Dardel cluster in Stockholm, Sweden

- When running on a cluster using the `slurm` job scheduler, ensure you provide a project allocation number using the `--project` parameter. This can be on the command line or via the `params.yml` file

`pixi run nextflow main.nf -profile pdc_kth -params-file params.yml --project example-allocation-12345`

- It is usually good practice to run `grave` via a `tmux` or `screen` session rather than directly on the login node. An editable shell script that will do this for you is available in `bin/slurm_submission.sh`

## Workflow outputs

>[!TIP]
> By default results are stored in the `results` directory. Exact outputs depend on the settings used.

| Output directory      | Description                                                                                                               |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------|
| 01_pipeline_info      | Package versions, run parameters, and Nextflow trace reports (if set)                                                     |
| 02_reference          | Reference statistics and reference FASTA files extracted from graphs with Pan-SN headers + index                          |
| 03_read_qc            | Read QC reports                                                                                                           |
| 04_mapped_reads       | Mapped reads (GAMs at library level, surjected BAMs sample merged and deduplicated), alignment statistics, failed samples |
| 05_post_mortem_damage | Post-mortem damage profiles (only for samples with the `ancient` metadata tag)                                            |
| 06_genotyping         | Genotyping outputs directly from the graph, and per sample                                                                |
| 07_variant_calling    | Variant calling outputs per sample                                                                                        |

>[!TIP]
> The workflow also computes graph indexes and snarls, stored in a folder alongside the input graph (detected on repeat runs)

![Storedir example](assets/storedir.png)

## Genotyping and variant calling

>[!TIP]
> `grave` outputs BAM files surjected to reference assemblies in the graph, therefore users can use these in custom downstream tools

### Provided genotyping tools

#### vg deconstruct

- `vg deconstruct` produces a VCF file with a line for every snarl (bubble) in the graph. Allele information (reference vs alt) is taken from paths in the graph, read more [here](https://github.com/vgteam/vg/wiki/VCF-export-with-vg-deconstruct)

#### vg call

- `vg call` genotypes graph variants present in each mapped sample (i.e., no novel variant calling), read more [here](https://github.com/vgteam/vg/wiki/SV-Genotyping-and-variant-calling#genotyping-a-VCF-using-the-graph)
- It takes GAM files as input, and therefore users should note that no deduplication is done prior to genotyping, see [here](https://github.com/vgteam/vg/issues/3283)

### Provided variant calling tools

#### Freebayes

- `Freebayes` is integrated in `grave`, read more [here](https://github.com/freebayes/freebayes)

#### DeepVariant

- `DeepVariant` is integrated in `grave` (currently recommended for human input data only), read more [here](https://github.com/google/deepvariant)

## Linear reference mode

- `grave` can be run in linear reference mode, mapping reads against a single FASTA reference instead of a graph

- Ancient DNA alignment will be run with `BWA aln` (`-l 16500 -n 0.01 -o 2`) and modern DNA with `BWA MEM` (default settings)

- To configure linear mode, set the parameter `reference_type` to `linear`, and provide a FASTA reference with the `reference` parameter
