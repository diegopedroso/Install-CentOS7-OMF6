import json
import sys

nodes_file_name = sys.argv[1]
resources_template_file_name = sys.argv[2]
resources_file_name = sys.argv[3]

template_file = open(resources_template_file_name, 'r')
nodes_file = open(nodes_file_name, 'r')
resources_file = open(resources_file_name, 'w')

resources_template = ""

for line in template_file:
    resources_template +=line

all_nodes = ""

for idx, line in enumerate(nodes_file):
    line = line.rstrip()
    if not line.startswith("#") and line:
        node_parts = line.split(", ")
        node = resources_template.replace("<name>", node_parts[0])
        node = node.replace("<ip-if0>", node_parts[1])
        node = node.replace("<mac-if0>", node_parts[2])
        node = node.replace("<mac-if1>", node_parts[3])
        node = node.replace("<ip-cmc>", node_parts[4])
        node = node.replace("<mac-cmc>", node_parts[5])
        node = node.replace("<domain>", node_parts[6])
        node = node.replace("<ip-gateway>", node_parts[7].rstrip())

        all_nodes += node + ",\n"

resources_file.write("[\n" + all_nodes[0:len(all_nodes)-2] + "\n]")
