#!/bin/bash

set -e

TARGET='//junk/ohmmeter:ohmmeter_venv'
VENV_LOCATION='.ohmmeter_venv'
WORKSPACE_DIR='/workspaces/jupyter'
NOTEBOOK_DIR="/workspaces/av/junk/$AVRIDE_LOGIN"

./vscode-extensions.sh

if [ ! -d "$WORKSPACE_DIR" ]; then
    # git clone https://github.com/avride/av "$WORKSPACE_DIR"
    git worktree add "$WORKSPACE_DIR" ohmmeter-jupyter
fi

cd $WORKSPACE_DIR
git fetch origin main
git rebase origin/main || git rebase --abort || true
git push -f

PATH="/home/vscode/.nix-profile/bin:$PATH"
bazelisk build $TARGET --check_visibility=false

tmux new-session -d -s jupyter || echo "Session already exists."
sleep 5
tmux send-keys -t jupyter "
    cd $WORKSPACE_DIR
    bazelisk run $TARGET
    source $VENV_LOCATION/bin/activate
    jupyter lab \
    --ip '::' \
    --no-browser \
    --ServerApp.root_dir='/workspaces/av' \
    --ServerApp.notebook_dir=$NOTEBOOK_DIR \
    --NotebookApp.custom_display_url=http://$WORKSPACE_FQDN:8888 \
" C-m
