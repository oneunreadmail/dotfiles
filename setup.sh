#!/bin/bash

set -e

TARGET='//junk/ohmmeter:ohmmeter_venv'
VENV_LOCATION='.ohmmeter_venv'
WORKSPACE_DIR='/workspaces/jupyter'
DEFAULT_URL="/tree/junk/$AVRIDE_LOGIN"

if [ ! -d "$WORKSPACE_DIR" ]; then
    cd '/workspaces/av'
    git worktree add "$WORKSPACE_DIR" ohmmeter-jupyter
fi

cd $WORKSPACE_DIR

git stash || true
git switch ohmmeter-jupyter
git fetch origin main
git merge origin/main --no-edit || {
    echo "Merge conflict detected. Please resolve manually."
    exit 1
}
git push origin ohmmeter-jupyter || true
git stash pop || true

PATH="/home/vscode/.nix-profile/bin:$PATH"
bazelisk build $TARGET --check_visibility=false

tmux new-session -d -s jupyter || echo "Session already exists."
sleep 5
tmux send-keys -t jupyter "
    cd $WORKSPACE_DIR
    bazelisk run $TARGET --check_visibility=false
    source $VENV_LOCATION/bin/activate
    jupyter-lab \
    --ip '0.0.0.0' \
    --no-browser \
    --ServerApp.root_dir='/workspaces/av/' \
    --NotebookApp.default_url=$DEFAULT_URL \
    --NotebookApp.custom_display_url=http://$WORKSPACE_FQDN:8888 \
" C-m
