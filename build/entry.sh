#!/bin/bash -e

GRE_ID=${GRE_ID-42}

my_ip() {
	ip addr show dev eth0 | grep -o "inet [1-9][^/]*" |cut -d" " -f2
}

nodejson() {
	cat << EOF
{
	"Node": "`hostname`",
	"Address": "`my_ip`",
	"NodeMeta": {
		"role":"SCS-node",
		"register_time":"`date +%s`"
	}
}
EOF
}

if [ "$role" = node ]; then

	# poor man's (k8s-less) service discovery for the testbed:
	while [ -z "$hub" ]; do
		hub=`curl -s "http://sd:8500/v1/kv/hub_endpoint?raw"`
		echo "trying to reach [$hub]..."
		if ! ping -c1 -w2 "$hub" ; then
			hub=""
			sleep 1
		fi
	done

	# register ourselves:
	curl -i -X PUT --data "`nodejson`" "http://sd:8500/v1/catalog/register"
	echo "node [`my_ip`] registered."

	# setup interface and peer
	vxlan_dev=vxlan$GRE_ID
	ip link add $vxlan_dev type vxlan id $GRE_ID dev eth0 dstport 0
	echo "network interface [$vxlan_dev] created."
	bridge fdb append to 00:00:00:00:00:00 dst $hub dev $vxlan_dev
	echo "fdb for [$vxlan_dev] set."

	ip a a 192.168.1.`my_ip|cut -d. -f4`/24 dev $vxlan_dev
	ip link set $vxlan_dev up
	echo "interface [$vxlan_dev] brought up."

	# jump into interactive shell for now...
	exec bash

elif [ "$role" = hub ]; then

	# register in sd:
	curl -s -X PUT --data $(my_ip) "http://sd:8500/v1/kv/hub_endpoint?raw"

	vxlan_dev=vxlan$GRE_ID
	# discover:
	curl -s 'http://sd:8500/v1/catalog/nodes?node-meta=role:SCS-node' \
		| jq -r '.[].Address' \
		| while read node; do
		echo "node: $node"
		# bridge fdb append to 00:00:00:00:00:00 dst $node dev $vxlan_dev
	done
	ip link add $vxlan_dev type vxlan id $GRE_ID dev eth0 dstport 0
	ip addr add 192.168.1.254/24 dev $vxlan_dev
	ip link set $vxlan_dev up

	# jump into interactive shell for now...
	exec bash
fi
