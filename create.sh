#!/bin/bash

set -e

DEV=/home/alnvdl/dev
WORKSPACE_DIR=/workspaces/workspace
WORKSPACE_FILE=$WORKSPACE_DIR/workspace.code-workspace
WORKSPACE_DEVCONTAINER=$WORKSPACE_DIR/.devcontainer/devcontainer.json

GO_URL="https://go.dev/dl/go1.21.4.linux-amd64.tar.gz"
GO_SUM="73cac0215254d0c7d1241fa40837851f3b9a8a742d0b54714cbdfb3feaf8f0af"

NODE_URL="https://nodejs.org/dist/v20.9.0/node-v20.9.0-linux-x64.tar.xz"
NODE_SUM="9033989810bf86220ae46b1381bdcdc6c83a0294869ba2ad39e1061f1e69217a"
NODE_EXT=".tar.xz"

# Prepare the dev folder.
mkdir $DEV
cd $DEV

# Install go.
wget $GO_URL
go_file=`basename $GO_URL`
echo "$GO_SUM $go_file" | sha256sum --check
tar xzf $go_file
mv $go_file go

export PATH=$PATH:$DEV/go/bin
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

# Clone repos and build VSCode workspace.
REPOS=$(cat $WORKSPACE_DEVCONTAINER | jq -r ".customizations.codespaces.repositories | keys_unsorted[]")
WORKSPACE_REPOS=""
for repo in $REPOS; do
    echo "Cloning $repo...";
    git clone https://github.com/$repo.git;
    repo_name=`basename $repo`
    WORKSPACE_REPOS="${WORKSPACE_REPOS} {\"path\": \"${DEV}/${repo_name}\"}"
done;
# Put commas between the repo elements.
export WORKSPACE_REPOS=${WORKSPACE_REPOS//\} \{/\}, \{}

tmp=$(mktemp)
envsubst < $WORKSPACE_FILE > $tmp
cat $tmp | jq -rM > $WORKSPACE_FILE
cd $WORKSPACE_DIR; git update-index --skip-worktree $WORKSPACE_FILE; cd -
