#!/bin/bash

set -e

DEV_DIR=/home/alnvdl/dev
WORKSPACE_DIR=$(dirname "$(realpath "$0")")

GO_URL="https://go.dev/dl/go1.24.0.linux-amd64.tar.gz"
GO_SUM="dea9ca38a0b852a74e81c26134671af7c0fbe65d81b0dc1c5bfe22cf7d4c8858"

NODE_URL="https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz"
NODE_SUM="69b09dba5c8dcb05c4e4273a4340db1005abeafe3927efda2bc5b249e80437ec"

# Prepare the dev folder.
mkdir $DEV_DIR
cd $DEV_DIR

# Install go.
wget $GO_URL
go_file=`basename $GO_URL`
echo "$GO_SUM $go_file" | sha256sum --check
tar xzf $go_file
mv $go_file go

export PATH=$PATH:$DEV_DIR/go/bin
go install -v golang.org/x/tools/gopls@latest
go install -v github.com/go-delve/delve/cmd/dlv@latest

# Install node.
wget $NODE_URL
node_file=`basename $NODE_URL`
echo "$NODE_SUM $node_file" | sha256sum --check
tar xJf $node_file
node_dir=`basename $node_file .tar.xz`
mv $node_dir node
mv $node_file node

# Set shell config.
cat <<EOF >> /home/alnvdl/.bashrc
export PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\[\033[00m\]\[\033[01;34m\]\w\[\033[00m\] \\$ '

export LANG=en_US.UTF-8
export LANGUAGE=
export LC_CTYPE=pt_BR.UTF-8
export LC_NUMERIC=pt_BR.UTF-8
export LC_TIME=pt_BR.UTF-8
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY=pt_BR.UTF-8
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER=pt_BR.UTF-8
export LC_NAME=pt_BR.UTF-8
export LC_ADDRESS=pt_BR.UTF-8
export LC_TELEPHONE=pt_BR.UTF-8
export LC_MEASUREMENT=pt_BR.UTF-8
export LC_IDENTIFICATION=pt_BR.UTF-8
export LC_ALL=
EOF

# Disable mnemonics in GTK apps to prevent weird issues with the Broadway
# display server.
mkdir -p /home/alnvdl/.config/gtk-3.0
cat <<EOF > /home/alnvdl/.config/gtk-3.0/settings.ini
[Settings]
gtk-enable-mnemonics = 0
EOF

# Clone repos and build VSCode workspace if there's a specific config.
WORKSPACE_DEVCONTAINER=$WORKSPACE_DIR/.devcontainer/$CONFIG/devcontainer.json
VSCODE_WORKSPACE_FILE=$WORKSPACE_DIR/workspace.code-workspace
if [ -n "$CONFIG" ]; then
    REPOS=$(cat $WORKSPACE_DEVCONTAINER | jq -r ".customizations.codespaces.repositories | keys_unsorted[]")
    WORKSPACE_REPOS=""
    for repo in $REPOS; do
        echo "Cloning $repo...";
        git clone https://github.com/$repo.git;
        repo_name=`basename $repo`
        WORKSPACE_REPOS="${WORKSPACE_REPOS} {\"path\": \"${DEV_DIR}/${repo_name}\"}"
    done;
    # Put commas between the repo elements.
    export WORKSPACE_REPOS=${WORKSPACE_REPOS//\} \{/\}, \{}

    tmp=$(mktemp)
    envsubst < $VSCODE_WORKSPACE_FILE > $tmp
    cat $tmp | jq -rM > $VSCODE_WORKSPACE_FILE
    cd $WORKSPACE_DIR; git update-index --skip-worktree $VSCODE_WORKSPACE_FILE; cd -
else
    rm -rf $VSCODE_WORKSPACE_FILE
fi;
