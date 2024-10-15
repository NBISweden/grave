# pan-aDNA

**Pangenomic analysis of ancient DNA**

## Description

**pan-aDNA** is a Nextflow workflow for mapping and genotyping ancient or modern samples against a pangenome graph reference.

As input it takes a pangenome graph in `.gbz` format and paired-end FASTQ data (from samples listed in a `.csv` samplesheet).

## Quick start

1. [Install Nextflow](https://www.nextflow.io/docs/latest/install.html) (uses DSL2, workflow was tested with v23.10.1)
2. [Install Apptainer](https://apptainer.org/docs/admin/main/installation.html)
3. Clone the Workflow repository: `git clone https://github.com/NBISweden/pan-adna.git`
4. In `data/reference`, add or link to the [reference graph](#reference-graphs-and-indexes)
5. Fill out the `.csv` samplesheet, [see layout description below](#samplesheet-layout)
6. Run the workflow with defaults: `nextflow main.nf`, or see the [parameters for more options](#parameters)

### Reference graphs and indexes

- pan-aDNA takes `.gbz` pangenome graphs as input, such as those produced by [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus)
- There are two main methods for building the graph with `Minigraph-Cactus`:
	1) haplotype sampling [best practice]
	2) coverage filtering
- The choice of method dictates whether to run pan-aDNA in `haplo` mode [default] or `filter` mode, described more below
- Because pan-aDNA is designed to handle very short reads, it recreates all graph indexes, and users only need to provide the `.gbz` file

#### Haplotype sampling

- Current best practice for mapping samples to pangenome graphs uses sample specific haplotype sampling, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling)
- To build the graph, run `MiniGraph-Cactus` with option: `--haplo` (`--giraffe` is not required)
- The clipped, unfiltered graph (e.g., `graph.gbz`) is used as input to `pan-aDNA`

#### Filtered graphs

- The previous method of building pangenome graphs for read mapping used coverage filtering to remove nodes not found in `x` haplotypes
- By default the `MiniGraph-Cactus` option `--giraffe` generates a graph filtered to depth 2. Haplotype support level can be adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`
- To use filtered graphs as input to `pan-aDNA`, the parameter `--referenceMode filter` should be set on the command line
- The clipped, filtered graph (e.g., `graph.d2.gbz`) is used as input to `pan-aDNA`

### Samplesheet layout

>[!TIP]
> The samplesheet should be in `.csv` format

| id            | type    | repeat | fastq1               | fastq2               |
|---------------|---------|--------|----------------------|----------------------|
| ancientHuman1 | ancient |   1    | /path/to/read1.fq.gz | /path/to/read2.fq.gz |
| ancientHuman1 | ancient |   2    | /path/to/read1.fq.gz | /path/to/read2.fq.gz |
| modernHuman7  | modern  |   1    | /path/to/read1.fq.gz | /path/to/read2.fq.gz |

- `id`: is the sample name
- `type`: is whether the sample is ancient or modern
- `repeat`: allows metadata separation between repeat runs of the same sample
- `fastq1`: relative or absolute path to the first fastq file
- `fastq2`: relative or absolute path to the second fastq file

## Parameters


-----
TODO:

--dup_calc_accuracy              accuracy level to calculate duplication with fastp (1~6), higher level uses more memory (1G, 2G, 4G, 8G, 16G, 24G). Default 3.

params.aDNA_discard_length = "30" - the length after trimming and merging that reads will need to pass to be retained by fastp (default 30) 
