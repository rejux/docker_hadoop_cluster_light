#!/bin/bash

echo "[INFO]"
echo "[INFO] ============================= "
echo "[INFO] update-ssh-auth-keys.sh"
echo "[INFO] ============================= "
echo "[INFO]"

ssh-copy-id -i $HOME/.ssh/id_rsa.pub hadoop@hadoop3-nn
ssh-copy-id -i $HOME/.ssh/id_rsa.pub hadoop@hadoop3-dn1
ssh-copy-id -i $HOME/.ssh/id_rsa.pub hadoop@hadoop3-dn2

exit 0

