#!/bin/bash
set -e
echo ":. creating cluster.."

 if [ ! "$KIND_CLUSTER" ] ; then
	echo ":. deploying simple cluster.."
	kind create cluster --config cluster-config.yaml
else
	export KIND_EXPERIMENTAL_DOCKER_NETWORK=lab-local
	if docker network ls | grep lab-local 2>&1 >/dev/null; then 
		echo ":. network 'lab-local' already exists" 
	else 
		echo ":. creating 'lab-local' network for lab..."
		docker network create --subnet=10.10.0.0/16 lab-local
	fi

	kind create cluster --name batman --config cluster-config-batman.yaml
	kind create cluster --name robin --config cluster-config-robin.yaml

	sleep 10
	kubectl --context kind-robin label nodes robin-worker node-role.kubernetes.io/database=true
	kubectl --context kind-robin taint nodes -l node-role.kubernetes.io/database=true dedicated=database:NoSchedule
	kubectl --context kind-batman label nodes batman-worker batman-worker2 node-role.kubernetes.io/database=true
	kubectl --context kind-batman taint nodes -l node-role.kubernetes.io/database=true dedicated=database:NoSchedule

fi

echo ":. bootstraping flux.."
[ ! "$KIND_BOOTSTRAP" ] && echo "no bootstrap" && exit 0
[ ! "$GITHUB_TOKEN" ] && echo "err: missing GITHUB_TOKEN" && exit 1
sleep 5 && flux bootstrap github \
--token-auth \
--owner=mulatinho \
--repository=sre \
--branch=main \
--path=kind/manifests \
--personal
