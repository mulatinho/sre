#!/bin/bash
set -e
[ ! "$GITHUB_TOKEN" ] && echo "err: missing GITHUB_TOKEN" && exit 1

echo ":. creating cluster.."
kind create cluster --config cluster-config.yaml

echo ":. bootstraping flux.."
sleep 5 && flux bootstrap github \
--token-auth \
--owner=mulatinho \
--repository=sre \
--branch=main \
--path=kind/manifests \
--personal

echo ":. making sure the folder is synced.."
sleep 5 && kubectl apply -f manifests/flux-system/gotk-sync.yaml
