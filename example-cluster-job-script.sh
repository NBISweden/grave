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

- add a new task definition to the pixi.toml, supplying more command line parameters

- or edit the pixi run command above to include the desired parameters, e.g.:

```
pixi run nextflow main.nf --graphMode filter --multiRef --deepVariant true -profile dardelLocal
```

END