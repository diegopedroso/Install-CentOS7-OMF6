omf6-testbed
============

This project has a set of scripts and configuration files to install all necessary modules 
to create a complete omf6 testbed.

Installation Guide
==================

Notes
-----
This script was tested in Ubuntu 14.04. It should work in later versions, but we not guarantee.

Environment
-----------

TODO here goes a description of a simple testbed environment with a figure.

Prerequirements
---------------
First, you need to install git and clone the project. For now, the indicated branch is amqp.
To maintain a pattern, use the root user and clone the project at **/root**.

    $apt-get install git
    $cd /root
    $git clone -b amqp https://github.com/LABORA-UFG/omf6-testbed.git

Configuration
-------------
Before execute the installer script, it is necessary to change some configuration files.

At conf/nodes.conf: you have to put a list of icarus nodes with its ips and macs.

At conf/interface-service-map.conf: you have to configure the interface interface of the control network.

At conf/testbed.conf: you have to put the DNS configuration of the nodes in your testbed.


Installation
------------
To install the testbed modules, you have to run the [installer.sh](installer.sh) script. The script
will show a list of options that allows you to install the modules separately or to install all
modules in a single machine.