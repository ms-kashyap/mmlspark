#!/bin/bash
# Copyright (C) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See LICENSE in project root for information.

usage() { echo "Usage: $(basename "$0") <vm-name> [<username>] "; exit 0; }

if [[ "x$1" == "x" ]]; then usage; else vmname="$1"; shift; fi
user="$1"; shift

wasb_dir="wasb:///MML-GPU"
wasb_private="$wasb_dir/identity"
wasb_public="$wasb_dir/identity.pub"
local_private="$HOME/.ssh/id_rsa"
local_public="$HOME/.ssh/id_rsa.pub"

# Create the directory if needed
hdfs dfs -test -d "$wasb_dir" || hdfs dfs -mkdir "$wasb_dir"

if ! hdfs dfs -test -e "$wasb_private"; then
  if [[ ! -f "$local_private" ]]; then
    ssh-keygen -f "$local_private" -t rsa -N "" -C "CNTK-access-key"
  fi
  hdfs dfs -copyFromLocal "$local_private" "$wasb_private"
  hdfs dfs -copyFromLocal "$local_public" "$wasb_public"
fi

echo ""
echo "Copying public key to the virtual machine"
if ssh-copy-id -i "$local_public" -o StrictHostKeyChecking=no "$user${user:+@}$vmname"; then
  echo "SSH keys were set up successfully"
else
  echo "Key copying failed!" 1>&2; exit 1
fi