#!/bin/bash -l
#SBATCH -A <my-project-allocation>
#SBATCH -t 24:00:00
#SBATCH -p main
#SBATCH -N 1
#SBATCH --mem=220GB
#SBATCH -J my-job-name
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=myemail@somewhere.com


# Go to grave repository

cd /path/to/grave


# Run grave using a predefined pixi task (see pixi.toml)

pixi run grave-dardel-default


# See below for more info

: <<'END'

To run grave with other settings, either:

- add a task definition to the pixi.toml, supplying more command line parameters

- use `pixi shell` (instead of pixi run above) & run nextflow directly:

```
pixi shell
nextflow main.nf --graphMode filter --refPaths --deepVariant true -profile dardelLocal
```

END