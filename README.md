# pan-aDNA

**Pangenomic analysis of ancient DNA**

## Description

**pan-aDNA** is a Nextflow workflow for mapping and genotyping ancient/modern samples against a pangenome graph reference.

As input it takes an indexed pangenome graph and paired-end FASTQ data (from 1+ samples detailed in a csv samplesheet).

## Quick start

1. [Install Nextflow](https://www.nextflow.io/docs/latest/install.html) (requires DSL2, workflow was tested with v23.10.1)
2. [Install Apptainer](https://apptainer.org/docs/admin/main/installation.html)
3. Clone the Workflow repository: `git clone https://github.com/NBISweden/pan-adna.git`
4. In `data/reference`, add or link to the [reference graph and indexes](#reference-graphs-and-indexes)
5. Fill out the `.csv` samplesheet, [see layout description below](#samplesheet-layout)
6. Run the workflow with defaults: `nextflow main.nf`, or see the [parameters for more options](#parameters)

### Reference graphs and indexes

- The pangenome graph and indexes are made upstream with software such as [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md), part of the [Cactus package](https://github.com/ComparativeGenomicsToolkit/cactus)
- `pan-aDNA` uses `vg giraffe` for read mapping
- Reference files for `giraffe` differ depending on how the graph was made, explained below
- Either way, graph and indexes should be placed or linked to in `data/reference`

#### Haplotype sampling

- Best practice for mapping with `vg giraffe` is to use haplotype sampling, read more [here](https://www.nature.com/articles/s41592-024-02407-2) and [here](https://github.com/vgteam/vg/wiki/Haplotype-Sampling)
- For graph and index building, use `MiniGraph-Cactus` option: `--haplo`  (`--giraffe` is not required)
- The files needed for pan-aDNA in `haplo` mode are:

```
myGraph.gbz
myGraph.hapl
```

- This is the default input for `pan-aDNA` (equivalent to supplying `pan-aDNA` the parameter `--referenceMode haplo`)

#### Filtered graphs

- Prior to the introduction of haplotype sampling, `vg giraffe` was run on graphs filtered at a haplotype support threshold (i.e., nodes were removed from the graph if they weren't supported by the minimum number of haplotypes - which meant the rarest variants in a population would be lost)
- The `MiniGraph-Cactus` option `--giraffe` generates a filtered graph by default. Haplotype support level can be adjusted with the `--filter` option, e.g.: `--giraffe --filter 10`
- To use filtered graphs as input, the `pan-aDNA` parameter `--referenceMode filter` should be used
- The files needed for pan-aDNA in `filter` mode are:
```
myGraph.d2.gbz
myGraph.d2.dist
myGraph.d2.min

# Where the `d2` reflects the haplotype depth support of 2 required for each node
```

### Samplesheet layout

>[!TIP]
> The samplesheet must be in `.csv` format

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
