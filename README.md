[![Pixi Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)
![Nextflow](https://img.shields.io/badge/Nextflow-v25.04.6-brightgreen)

# grave

**Graph Variant Explorer: Pangenomic analysis of ancient or modern DNA**

## Description

`grave` is a Nextflow workflow for mapping, genotyping, and variant calling ancient or modern samples against a pangenome graph. The steps are shown graphically [here](#pipeline-overview).

As input it takes a pangenome graph in `.gbz` format and either paired-end or merged FASTQ data (from samples listed in a `.csv` samplesheet).

Outputs are described [here](#workflow-outputs).

More information on genotyping and variant calling is found [here](#genotyping-and-variant-calling).

It is recommended to construct the graph with [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md). Before doing so, read this [section](#input-fasta-naming).

## Quick start

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/NBISweden/grave)

>[!TIP]
>The base image includes pixi, Nextflow, Apptainer, wave, & nf-core tools. There is a 4-core minimum requirement to run the test

### Local or HPC installation

1. [Install Pixi](https://pixi.sh/latest/installation/): `curl -fsSL https://pixi.sh/install.sh | sh`
2. Clone the Workflow repository: `git clone https://github.com/NBISweden/grave.git`
3. Run `pixi install` (or `pixi install -e apptainer` for Apptainer support)

>[!NOTE]
>The pixi project contains two environments:<br><br>
>`default`: installed with `pixi install` - lacks apptainer (e.g. for systems with their own Apptainer installation)<br><br>
>`apptainer`: installed with `pixi install -e apptainer` - provides Apptainer support

<details>

<summary><h3>Introduction to pixi (drop down)</h3></summary>

- `grave` can run with only `Nextflow` and `Apptainer` installed in `$PATH`, but for reproducibility it is recommended to run it via `pixi`
- `pixi` is a drop-in replacement for `conda`, and is used to easily and reproducibly share tested environments for running software
- `pixi` environments have an editable manifest file of direct dependencies, the `pixi.toml`
- Solved environments also have a `pixi.lock` file, which lists exact versions of all dependencies including transitive ones - the lockfile in this repository defines a tested environment for Linux systems
- Installed `pixi` environments are found in the hidden folder `.pixi/envs`
- `pixi` will automatically install an environment it lacks, if implied by another command (e.g., `pixi run -e apptainer ...` would install the `apptainer` environment even if the `default` environment is the only one currently installed)
- You can run commands from outside the default `pixi` environment by prefixing them with `pixi run`, or in a specific environment with `pixi run -e <environment>`
- You can also shell inside the default `pixi` environment with `pixi shell`, or into a specific environment with `pixi shell -e <environment>`, similar to `conda activate <environment>` (at this point you no longer need the `pixi run` prefix)
- To delete an environment: `rm -rf .pixi/envs/<environment_name>`

</details>

### Run grave with test data

Run with the provided test data: `pixi run test`

>[!TIP]
> All `pixi run` commands assume the `default` environment. To use the `apptainer` environment, add `-e apptainer`, e.g.:<br><br>
>`pixi run -e apptainer test`

### Run grave with your data

1. [Input file setup](#file-setup)
2. Run with defaults: `pixi run grave` (equivalent to `pixi run nextflow main.nf -profile apptainer`). Or run with custom parameters, e.g.: `pixi run nextflow main.nf --graphMode filter --account naiss2049-87-324 -profile apptainer,dardelSlurm`

>[!TIP]
>For help with command line options: `pixi run help`<br><br>
>An example shell script for running `grave` on a cluster with SLURM is provided in the repo: `example-cluster-job-script.sh`

### File setup

1. Generate or provide a [graph file](#graphs). By default `grave` looks for a `.gbz` file in `data`
2. Fill out a `samplesheet.csv` including file system paths to the reads. By default `grave` looks for this in `data`. [See layout description below](#samplesheet-layout)
3. Was your graph built with [more than one reference sample](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#Reference-Sample)? **If no, you are done**. If yes, [read this section first](#multiple-reference-samples)

#### Input fasta naming

- When using `Minigraph-Cactus` for graph construction, please take note to keep contig names for the input FASTAs as simple as possible, [see the official guidance here](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#contig-names)

>[!WARNING]
>Crucially: avoid hash characters in contig names

#### Graphs

- `grave` takes `.gbz` pangenome graphs as input, such as those produced by [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus)

>[!TIP]
>Note on idex files: Because `grave` is designed to handle very short reads (i.e., aDNA at <50 bp) in addition to typical (100-150 bp) short reads, it recreates all graph indexes, and users only need to provide the `.gbz` file

- There are two main methods for building the graph with `Minigraph-Cactus`:
	1) build an unfiltered graph, for downstream haplotype sampling prior to mapping [**best practice**]
	2) build a graph with low coverage nodes filtered out

- The choice of method impacts whether to run `grave` in `haplo` mode [default] or `filter` mode, described more below

##### Haplotype sampling

- Current best practice for mapping samples to pangenome graphs utilises sample specific haplotype sampling from the graph, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling)

- To build the graph, run `MiniGraph-Cactus` with option: `--haplo` (`--giraffe` is not required)

- The clipped, unfiltered graph (e.g., `graph.gbz`) is used as input to `grave`

##### Filtered graphs

- The other method of building pangenome graphs for read mapping uses coverage filtering to remove nodes not found in a set number of haplotypes

- By default the `MiniGraph-Cactus` option `--giraffe` generates a graph filtered to depth 2. Coverage support level can be adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`

- To use a filtered graph with `grave`, the parameter `--graphMode filter` should be set on the command line

- The clipped, filtered graph (e.g., `graph.d2.gbz`) is used as input to `grave`

#### Samplesheet layout

>[!TIP]
> The table below is for example purposes - the samplesheet must be in `.csv` format

| id            | repeat | type    | merged | fastq1                | fastq2               |
|---------------|--------|---------|--------|-----------------------|----------------------|
| ancientHuman1 |   1    | ancient | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| ancientHuman1 |   2    | ancient | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| modernHuman7  |   1    | modern  | false  | /path/to/read1.fq.gz  | /path/to/read2.fq.gz |
| mergedInput   |   1    | ancient | true   | /path/to/merged.fq.gz |                      |

- `id`: sample name

- `repeat`: unique identifier for repeat runs on the same sample

- `type`: sample is ancient or modern - **Note:** _this affects how the sample will be processed_

- `merged`: whether the reads have already been merged (e.g., some ancient samples)

- `fastq1`: relative or absolute path to the first FASTQ

- `fastq2`: relative or absolute path to the second FASTQ

#### Multiple reference samples

- `Minigraph-Cactus` requires at least one reference sample, usually the most contiguous reference assembly, e.g.: `cactus-pangenome --reference GRCh38`

- Paths through the reference sample are _reference paths_. Unless configured otherwise, `grave` will assume __a single reference sample__, and use rational defaults that assume the same, for example `surject` will transform GAM alignments to linear BAM relative to __all reference paths__ in the graph. If there is more than one reference sample in the graph, this will cause undesirable outputs in certain steps, and errors in others

- Therefore, if your graph was built with multiple reference samples, e.g.: `cactus-pangenome --reference GRCh38 chimp gorilla`, it is required to run `grave` with `--multiRef`, and to provide one or more `.paths` files. By default `grave` looks for these in the `data/paths` directory

- Each `.paths` file contains a list of reference paths from one reference sample, with one path name per line

- __The name of the `.paths` file matters__: the prefix must match a reference sample name provided in the `seqFile` of `Minigraph-Cactus`, and the suffix must be `.paths`, e.g.: `GRCh38.paths`, `chimp.paths`, & `gorilla.paths`

>[!TIP]
> `vg` is packaged in the pixi environment, to see the reference samples in your graph run: `pixi run vg paths --reference-paths --metadata -x myGraph.gbz | cut -f3 | tail -n+2 | sort | uniq`<br><br>
> For a list of all reference path names from, for example GRCh38, run: `pixi run vg paths --reference-paths --metadata -x myGraph.gbz | tail -n+2 | awk '$3 == "GRCh38"' | cut -f1 > GRCh38.paths`

- For each `.paths` file provided, `grave` will run pipeline steps relative to that sample separately from the others, e.g., `surject` will produce a separate `.bam` file per reference sample, such that surjecting `unknownSimian.1.gam` to `chimp.paths` and `gorilla.paths` will produce:

```
unknownSimian.1.chimp.bam
unknownSimian.1.gorilla.bam
```


## Workflow outputs

>[!TIP]
> Results are stored in the `results` directory. Exact outputs depend on the settings used (`pixi run help`), but the following can be configured:

| Output directory  | Description                                                                                                           |
|-------------------|-----------------------------------------------------------------------------------------------------------------------|
| genotyping        | Genotyping outputs directly from the graph, & per sample                                                              |
| linear_references | Graph reference assemblies in FASTA format with Pan-SN headers + index                                                |
| mapped_files      | GAM files, & BAMs surjected to respective graph references                                                            |
| package_versions  | Tool version report                                                                                                   |
| pmd_profiles      | Post-mortem damage assessments (only for samples with the `ancient` metadata tag)                                     |
| quality_reports   | FASTQC reports for both raw reads & quality controlled + merged reads, fastp reports at the library and sample levels |
| statistics        | Graph statistics & metadata, & alignment statistics per sample                                                        |
| variant_calling   | Variant calling outputs per sample                                                                                    |

>[!TIP]
> The workflow also computes graph snarls and indexes. These are stored in a folder alongside the input graph, and are detected on repeat runs (also if using a shared file system), but are not considered workflow outputs

![Storedir example](assets/storedir.png)

## Genotyping and variant calling

>[!TIP]
> `grave` outputs BAM files surjected to reference assemblies in the graph, therefore users can use these in custom downstream tools

### Provided genotyping tools

#### vg deconstruct

- `vg deconstruct` produces a VCF file with a line for every snarl (bubble) in the graph. Allele information (reference vs alt) is taken from paths in the graph, read more [here](https://github.com/vgteam/vg/wiki/VCF-export-with-vg-deconstruct)

#### vg call

- `vg call` genotypes graph variants present in each mapped sample (i.e., no novel variant calling), read more [here](https://github.com/vgteam/vg/wiki/SV-Genotyping-and-variant-calling#genotyping-a-VCF-using-the-graph)

### Provided variant calling tools

#### Freebayes

- `Freebayes` is integrated in `grave`, read more [here](https://github.com/freebayes/freebayes)

#### DeepVariant

- `DeepVariant` is integrated in `grave` (recommended for human input data), read more [here](https://github.com/google/deepvariant)

## Pipeline overview

![Workflow](assets/workflow-dag.png)
