# pan-aDNA

**Pangenomic analysis of ancient DNA**

## Description

**pan-aDNA** is a Nextflow workflow for mapping and genotyping ancient/modern samples against a pangenome graph reference.

As input it takes paired-end fastq files from one or more samples and an indexed pangenome graph.

## Quick start

1. [Install Nextflow](https://www.nextflow.io/docs/latest/install.html) (requires DSL2, workflow was tested with v23.10.1)
2. [Install Apptainer](https://apptainer.org/docs/admin/main/installation.html)
3. Clone the Workflow repository: `git clone https://github.com/NBISweden/pan-adna.git`
4. In `data/reference`, add or link to the [reference graph and indexes](#reference-graphs-and-indexes)
5. Fill out the `.csv` samplesheet, [see layout description below](#samplesheet-layout)
6. Run the workflow with defaults: `nextflow main.nf`, or see the [parameters for more options](#parameters)

### Reference graphs and indexes

- The pangenome graph and indexes are made upstream with software such as [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus)
- `pan-aDNA` uses `vg giraffe` for read mapping, but the input files differ  depending on how the graph was made, explained below
- Graph and indexes should be placed or linked to in `data/reference`

#### Haplotype sampling

- Current best practice for read mapping with `vg giraffe` is to utilise haplotype sampling, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling)
- The graph and indexes for this are made using the `MiniGraph-Cactus` options: `--haplo --giraffe clip`
- The four required files are:
```
myGraph.gbz
myGraph.hapl
myGraph.dist
myGraph.min
```
- By default `pan-aDNA` assumes the reference graph was made with haplotype sampling (equivalent to supplying `pan-aDNA` the parameter `--referenceMode haplo`)

#### Filtered graphs

- Before haplotype sampling was supported, `vg giraffe` was run on filtered graphs, in which nodes were removed if they weren't supported by a minimum number of haplotypes
- The `MiniGraph-Cactus` option `--giraffe` generates a filtered graph (minimum 2 supporting haplotypes) and indexes. Minimum haplotype support is adjusted with `--filter` option, e.g.: `--giraffe --filter 10`
- To use filtered graphs as input, the `pan-aDNA` parameter `--referenceMode filter` should be used 
- The three required files are:
```
myGraph.d2.gbz
myGraph.d2.dist
myGraph.d2.min

# The number reflects the minimum haplotype support for each node
```

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
