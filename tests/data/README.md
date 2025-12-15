# Data

```
data
├── README.md
├── fastq
│   ├── README.md
│   ├── ancientApe_lib2_s1.fq.gz
│   ├── ancientApe_lib2_s1.repeat.fq.gz
│   ├── ancientApe_lib2_s2.fq.gz
│   ├── ancientApe_lib2_s2.repeat.fq.gz
│   ├── ancientApe_s1.fq.gz
│   ├── ancientApe_s2.fq.gz
│   ├── ancientMerged.fq.gz
│   ├── ancientSimian_s1.fq.gz
│   ├── ancientSimian_s2.fq.gz
│   ├── modernHuman_s1.fq.gz
│   └── modernHuman_s2.fq.gz
├── graph
│   ├── README.md
│   ├── additional_graphs
│   │   ├── example-filtered.d2.gbz
│   │   └── example-multiple-reference-samples.gbz
│   └── example-unfiltered.gbz
├── paths
│   ├── README.md
│   ├── simChimp.paths
│   └── simGorilla.paths
└── samplesheet.csv
```

## Samplesheet

CSV file with the following column headers:

```
sample_id,library_id,repeat_number,sample_type,merged,fastq_1,fastq_2
```

- sample_id: unique sample identifier

- library_id: unique library identifier

- repeat_number: repeat number of the library

- sample_type: sample is ancient or modern - Note: this affects how the sample will be processed

- merged: whether the reads have already been merged (e.g., some ancient samples)

- fastq1: relative or absolute path to the first FASTQ

- fastq2: relative or absolute path to the second FASTQ
