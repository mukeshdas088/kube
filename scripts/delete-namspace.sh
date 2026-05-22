#!/bin/bash
echo "enter the namespace name :"
read name
if [ -n "$name" ] ; then

	output=$(kubectl config set-context --current --namespace=default;kubectl delete namespace $name)
	echo "$output"
else 
	echo "no name provided"
fi
