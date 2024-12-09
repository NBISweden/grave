# Grave

**Graph Variant Explorer: Pangenomic analysis of ancient or modern DNA**

## Description

`grave` is a Nextflow workflow for mapping and genotyping ancient or modern samples against a pangenome graph. The steps are visually shown [here](#pipeline-overview).

As input it takes a pangenome graph in `.gbz` format and paired-end FASTQ data (from samples listed in a `.csv` samplesheet).

It is recommended to construct the graph with [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md). Before doing so, read this [section](#input-fasta-naming).


## Quick start

>[!TIP]
>For help with command line options: `nextflow main.nf --help`, or see [here](#parameters).

1. [Install Nextflow](https://www.nextflow.io/docs/latest/install.html) (`grave` uses DSL2 & features introduced in `Nextflow 24.02.0-edge`. It was tested with `Nextflow v24.10.0`)
2. [Install Apptainer](https://apptainer.org/docs/admin/main/installation.html)
3. Clone the Workflow repository: `git clone https://github.com/NBISweden/grave.git`
4. In `data/graph`, add or link to the [graph](#graphs-and-indexes)
5. Fill out `data/samplesheet/samplesheet.csv` including paths to the reads, [see layout description below](#samplesheet-layout)
6. Was your graph built with [more than one reference sample](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#Reference-Sample)? **If no, go to step 7**. If yes, [read this section first](#multiple-reference-samples).
7. Run the workflow with defaults: `nextflow main.nf`, or see the [parameters for more options](#parameters)

### Input fasta naming

- When using `Minigraph-Cactus` for graph construction, please take note to keep contig names for the input FASTAs as simple as possible, [see the official guidance here](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#contig-names)

>[!WARN]
> But crucially: entirely avoid hash characters in contig names

### Graphs and indexes

- `grave` takes `.gbz` pangenome graphs as input, such as those produced by [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus)

- There are two main methods for building the graph with `Minigraph-Cactus`:
	1) haplotype sampling [best practice]
	2) coverage filtering

- The choice of method impacts whether to run `grave` in `haplo` mode [default] or `filter` mode, described more below

- Because `grave` is designed to handle very short reads, it recreates all graph indexes, and users only need to provide the `.gbz` file

#### Haplotype sampling

- Current best practice for mapping samples to pangenome graphs utilises sample specific haplotype sampling from the graph, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling)

- To build the graph, run `MiniGraph-Cactus` with option: `--haplo` (`--giraffe` is not required)

- The clipped, unfiltered graph (e.g., `graph.gbz`) is used as input to `grave`

#### Filtered graphs

- The other method of building pangenome graphs for read mapping uses coverage filtering to remove nodes not found in `x` haplotypes

- By default the `MiniGraph-Cactus` option `--giraffe` generates a graph filtered to depth 2. Coverage support level can be adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`

- To use a filtered graph with `grave`, the parameter `--graphMode filter` should be set on the command line

- The clipped, filtered graph (e.g., `graph.d2.gbz`) is used as input to `grave`

### Samplesheet layout

>[!TIP]
> The table below is for example purposes - the samplesheet must be in `.csv` format

| id            | type    | repeat | read_group             | fastq1               | fastq2               |
|---------------|---------|--------|------------------------|----------------------|----------------------|
| ancientHuman1 | ancient |   1    | FLOWCELL_ID.LANENUMBER | /path/to/read1.fq.gz | /path/to/read2.fq.gz |
| ancientHuman1 | ancient |   2    | FLOWCELL_ID.LANENUMBER | /path/to/read1.fq.gz | /path/to/read2.fq.gz |
| modernHuman7  | modern  |   1    | FLOWCELL_ID.LANENUMBER | /path/to/read1.fq.gz | /path/to/read2.fq.gz |

- `id`: the sample name

- `type`: whether the sample is ancient or modern - **Note:** _this affects how the sample will be processed_

- `repeat`: metadata separation between repeat runs on the same sample

- `read_group`: the read group name, usually `FLOWCELL_ID.LANENUMBER`, [see here](https://gatk.broadinstitute.org/hc/en-us/articles/360035890671-Read-groups)

- `fastq1`: relative or absolute path to the first FASTQ

- `fastq2`: relative or absolute path to the second FASTQ

### Multiple reference samples

- `Minigraph-Cactus` requires at least one reference sample, usually the most contiguous reference assembly, e.g.: `cactus-pangenome --reference GRCh38`

- Paths through the reference sample are _reference paths_. Unless configured otherwise, `grave` will assume __a single reference sample__, and use rational defaults that assume the same, for example `surject` will transform GAM alignments to linear BAM relative to __all reference paths__ in the graph. If there is more than one reference sample in the graph, this will cause undesirable outputs in certain steps, and errors in others

- Therefore, if your graph was built with multiple reference samples, e.g.: `cactus-pangenome --reference GRCh38 chimp gorilla`, it is required to run `grave` with `--refPaths true`, and to provide one or more `.paths` files in the `data/paths` directory

- Each `.paths` file contains a list reference paths from one reference sample (e.g., a subset or all paths), with one path name per line

- __The name of the `.paths` file matters__: the prefix must match a reference sample name provided in the `seqFile` of `Minigraph-Cactus`, and the suffix must be `.paths`, e.g.: `GRCh38.paths`, `chimp.paths`, & `gorilla.paths`

>[!TIP]
> You can remind yourself of the reference samples and path names in your graph using vg: `vg paths --reference-paths --metadata -x myGraph.gbz | cut -f3 | tail -n+2 | sort | uniq`

- For each `.paths` file provided, `grave` will run pipeline steps relative to that sample separately from the others, e.g., `surject` will produce a separate `.bam` file per reference sample, such that surjecting `unknownSimian.1.gam` to `chimp.paths` and `gorilla.paths` will produce:

```
unknownSimian.1.chimp.bam
unknownSimian.1.gorilla.bam
```

- Another use case for the `--refPaths` option is targeting a subset of reference paths found in one reference sample (one `.paths` file required) or multiple reference samples (multiple `.paths` files required), for example only the autosomes, or only chr1

## Pipeline overview

- TODO: ADD LATEST DAG


## Parameters

- TODO:

User supplied parameters follow the main script execution, e.g.: `nextflow main.nf --graphMode haplo`

| Parameter                | Description                                                                                                                       | Default | Options           |
|--------------------------|------------------------------------------------|--------------|------------------------------|
| `--help`                 | Prints the help message                                                                                                           | null    | NA                |
| `--graphMode`            | Set mode of operation based on the type of input graph, clipped & unfiltered [`haplo`], or clipped & filtered [`filter`]          | `haplo` | `haplo`, `filter` |
| `--graphCall`            | Control whether variants in the graph are called or not                                                                           | `true`  | `true`, `false`   |

