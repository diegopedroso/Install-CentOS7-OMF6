omf6-testbed
============

This project has a set of scripts and configuration files to create an omf6 testbed, 
installing all modules in a single machine.

Installation Guide
==================

Notes
-----
This script was tested in Ubuntu 14.04. It should work in later versions, but we not garantee.

Environment
-----------
TODO here goes a description of a simple testbed environment with a figure.

Prerequirements
---------------
First, you need to install git and clone the project. For now, the indicated branch is amqp.
To maintain a pattern, use the root user and clone the project at **/root**.

    $apt-get install git
    $cd /root
    $git clone -p amqp https://github.com/viniciusgb4/omf6-testbed.git

Configuration
-------------
Before execute, it is necessary to change some configuration files.

At conf/nodes.conf: you have to put a list of icarus nodes with its ips and macs.
At conf/interface-service-map.conf: you have to put configure the interfaces where the services will run.
At conf/testbed.conf: you have to put the DNS configuration of the nodes in your testbed.
