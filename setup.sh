#!/bin/bash

set -e

TARGET='//junk/ohmmeter:ohmmeter_venv'
VENV_LOCATION='.ohmmeter_venv'
WORKSPACE_DIR="/workspaces/jupyter"
HOSTNAME=$(hostname).coder.pods.max.avride.ai

echo $USER
export

if [ ! -d "$WORKSPACE_DIR" ]; then
    git clone https://github.com/avride/av "$WORKSPACE_DIR"
fi

cd "$WORKSPACE_DIR"
git pull || echo "Could not pull latest changes automatically."
su -l vscode -c "
    bazelisk run $TARGET
    sleep 1
    nohup $VENV_LOCATION/bin/jupyter lab --ip '::' --no-browser --IdentityProvider.token='' &
"

# tmux new-session -d -s jupyter || echo "Session already exists."
# sleep 5
# tmux send-keys -t jupyter "cd $WORKSPACE_DIR" C-m
# tmux send-keys -t jupyter "bazelisk run $TARGET" C-m
# tmux send-keys -t jupyter "source $VENV_LOCATION/bin/activate" C-m
# tmux send-keys -t jupyter "cd /workspaces/av" C-m
# tmux send-keys -t jupyter "jupyter notebook --ip '::' --NotebookApp.token='' C-m
