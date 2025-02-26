#!/bin/bash -l

# EDIT VARIABLES

GRAVE_REPO_PATH=~/grave
TMUX_SESSION_NAME=grave
PIXI_COMMAND="pixi run nextflow main.nf --graphDir ./data/test --samplesheet ./data/test/samplesheet.csv --pathsDir ./data/test/paths -profile standard"





### DO NOT EDIT BELOW THIS LINE ###

if [ -d "$GRAVE_REPO_PATH" ]; then

	cd $GRAVE_REPO_PATH

	tmux_version_output=$(tmux -V 2>&1)

	if [ $? -ne 0 ]; then
		echo "Error: tmux not found"
	else
		if echo "$tmux_version_output" | grep -q "^tmux "; then
			majorVersion=$(echo "$tmux_version_output" | sed 's/^tmux //;s/\..*$//')
			if [ "$majorVersion" -eq 1 ]; then
				tmux new-session -s "$TMUX_SESSION_NAME" -d
				tmux send-keys -t "$TMUX_SESSION_NAME" "$PIXI_COMMAND" C-m
				echo "Found tmux version $majorVersion"
				echo "Grave pipeline started in tmux session: '$TMUX_SESSION_NAME', with command:"
				echo "$PIXI_COMMAND"
				echo "Monitor workflow progress in '.nextflow.log' or with 'squeue -u $USER'"
			elif [ "$majorVersion" -ge 2 ]; then
				tmux new -s "$TMUX_SESSION_NAME" -d /bin/bash -c "$PIXI_COMMAND"
				echo "Found tmux version $majorVersion"
				echo "Grave pipeline started in tmux session: '$TMUX_SESSION_NAME', with command:"
				echo "$PIXI_COMMAND"
				echo "Monitor workflow progress in '.nextflow.log' or with 'squeue -u $USER'"
			fi
		else
			echo "Error: Unable to parse tmux version"
		fi
	fi

else

	echo "Error: '$GRAVE_REPO_PATH' does not exist, set to the grave repository path."

fi
