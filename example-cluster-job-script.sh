#!/bin/bash -l

# Go to grave repository (update path)

cd ~/grave

# Run grave in the background (edit options for your needs)

tmux new -s grave-run -d /bin/bash -c "pixi run nextflow main.nf --account "naiss2024-22-619" -profile dardelSlurm"

echo "Grave pipeline started in the background"
echo "You can monitor the progress in '.nextflow.log' and with 'squeue'"
