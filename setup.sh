#!/bin/bash

set -e

TARGET='//junk/ohmmeter:ohmmeter_venv'
VENV_LOCATION='.ohmmeter_venv'
WORKSPACE_DIR='/workspaces/jupyter'
HOSTNAME=$(hostname).coder.pods.max.avride.ai
NOTEBOOK_DIR=/workspaces/av/junk/$GITHUB_USER

if [ ! -d "$WORKSPACE_DIR" ]; then
    git clone https://github.com/avride/av "$WORKSPACE_DIR"
fi

cd "$WORKSPACE_DIR"
git pull || echo "Could not pull latest changes automatically."
mkdir -p $NOTEBOOK_DIR

PATH="/home/vscode/.nix-profile/bin:$PATH"
tmux new-session -d -s jupyter || echo "Session already exists."
sleep 5
tmux send-keys -t jupyter "cd $WORKSPACE_DIR" C-m
tmux send-keys -t jupyter "bazelisk run $TARGET" C-m
tmux send-keys -t jupyter "source $VENV_LOCATION/bin/activate" C-m
tmux send-keys -t jupyter "
    jupyter lab \
    --ip '::' \
    --no-browser \
    --IdentityProvider.token='' \
    --ServerApp.root_dir='/workspaces/av' \
    --ServerApp.notebook_dir=$NOTEBOOK_DIR \
    --NotebookApp.custom_display_url=http://$HOSTNAME:8888 \
" C-m
