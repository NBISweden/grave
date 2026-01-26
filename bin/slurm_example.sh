#!/bin/bash -l

############### Edit these values ###############

REPO_PATH=/path/to/repository/grave
PIPELINE_NAME=grave
TMUX_SESSION_NAME=grave
PIXI_COMMAND="pixi run nextflow main.nf -profile pdc_kth -params-file params.yml --project <ALLOCATION>"


############### No edit required below ###############

if [ -d "$REPO_PATH" ]; then

    cd $REPO_PATH

    TMUX_VERSION_OUTPUT=$(tmux -V 2>&1)

    if [ $? -ne 0 ]; then
        echo "Error: tmux not found"
    else
        if echo "$TMUX_VERSION_OUTPUT" | grep -q "^tmux "; then
            MAJORVERSION=$(echo "$TMUX_VERSION_OUTPUT" | sed 's/^tmux //;s/\..*$//')
            if [ "$MAJORVERSION" -eq 1 ]; then
                tmux new-session -s "$TMUX_SESSION_NAME" -d
                tmux send-keys -t "$TMUX_SESSION_NAME" "$PIXI_COMMAND" C-m
                cat << EOF
Welcome to $PIPELINE_NAME

Your job is running in the background via tmux version $MAJORVERSION (session name: $TMUX_SESSION_NAME).

The command supplied was:
$PIXI_COMMAND

You can monitor workflow progress either via the '.nextflow.log' file, or with 'squeue -u $USER'

View your active tmux sessions with: 'tmux list-sessions'

Cancel this job with: 'tmux kill-session -t $TMUX_SESSION_NAME'
EOF
            elif [ "$MAJORVERSION" -ge 2 ]; then
                tmux new -s "$TMUX_SESSION_NAME" -d /bin/bash -c "$PIXI_COMMAND"
                cat << EOF
Welcome to $PIPELINE_NAME

Your job is running in the background via tmux version $MAJORVERSION (session name: $TMUX_SESSION_NAME).

The command supplied was:
$PIXI_COMMAND

You can monitor workflow progress either via the '.nextflow.log' file, or with 'squeue -u $USER'

View your active tmux sessions with: 'tmux list-sessions'

Cancel this job with: 'tmux kill-session -t $TMUX_SESSION_NAME'
EOF
            fi
        else
            echo "Error: Unable to parse tmux version"
        fi
    fi

else

    echo "Error: '$REPO_PATH' does not exist, set to the $PIPELINE_NAME repository path."

fi
