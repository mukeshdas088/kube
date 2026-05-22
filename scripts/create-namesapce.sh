#!/bin/bash
echo "enter the namespace name :"
read name
if [ -n "$name" ] ; then
	output=$(kubectl create namespace $name;kubectl config set-context --current --namespace=$name)
	echo "$output"
else 
	echo "no name provided"
fi
