# omf6-testbed

This project has a set of scripts and configuration files to create a omf6 testbed, installing all modules in a single machine.
 
Before execute, it is necessary to change some configuration files.

## Configuration
At conf/nodes.conf: you have to put a list of icarus nodes with its ips and macs.
At conf/interface-service-map.conf: you have to put configure the interfaces where the services will run.
At testbed-files/etc/dnsmasq.d/testbed.conf: you have to put the DNS confgirution of the nodes in your testbed.
