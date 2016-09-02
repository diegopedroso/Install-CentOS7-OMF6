#!/bin/bash

INSTALLER_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $INSTALLER_HOME/variables.conf
source $INSTALLER_HOME/util.sh

install_dependencies() {
    echo 'deb http://pkg.mytestbed.net/ubuntu precise/ ' >> /etc/apt/sources.list \
    && apt-get update
    apt-get install -y --force-yes --reinstall \
       build-essential \
       curl \
       dnsmasq \
       frisbee \
       git \
       libsqlite3-dev \
       libreadline6-dev \
       libssl-dev \
       libyaml-dev \
       libxml2-dev \
       libxmlsec1-dev \
       libxslt-dev \
       links2 \
       ntp \
       python \
       syslinux \
       xmlsec1 \
       wget \
       zlib1g-dev

    cd /tmp \
       && wget http://ftp.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz \
       && tar -xvzf ruby-2.2.3.tar.gz \
       && cd ruby-2.2.3/ \
       && ./configure --prefix=/usr/local \
       && make \
       && make install \
       && rm -rf /tmp/ruby

    gem install bundler --no-ri --no-rdoc
}

install_omf() {
    cd /root
    git clone -b amqp https://github.com/viniciusgb4/omf.git
    cd $OMF_COMMON_HOME
    gem build omf_common.gemspec
    gem install omf_common-*.gem

    cd $OMF_RC_HOME
    gem build omf_rc.gemspec
    gem install omf_rc-*.gem

    cd $OMF_EC_HOME
    gem build omf_ec.gemspec
    gem install omf_ec-*.gem

    cd /root
    rm -rf $OMF_HOME
}

remove_omf() {
    gem uninstall omf_common -a -I --force -x
    gem uninstall omf_rc -a -I --force -x
    gem uninstall omf_rc -a -I --force -x
}

install_broker() {
    #if $OMF_SFA_HOME directory does not exist or is empty
    if [ ! "$(ls -A $OMF_SFA_HOME)" ] || [ ! "$(ls -A /root/.omf)" ]; then
        echo "###############INSTALLATION OF THE MODULES###############"
        #Start of Broker installation
        echo "###############GIT CLONE OMF_SFA REPOSITORY###############"
        cd /root
        echo $(pwd)
        echo $OMF_SFA_HOME
        git clone -b amqp https://github.com/viniciusgb4/omf_sfa.git
        cd $OMF_SFA_HOME
        echo "###############INSTALLING OMF_SFA###############"
        bundle install

        echo "###############RAKE DB:MIGRATE###############"
        rake db:migrate

        echo "###############CREATING DEFAULT SSH KEY###############"
        ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""

        ##START OF CERTIFICATES CONFIGURATION
        echo "###############CONFIGURING OMF_SFA CERTIFICATES###############"
        mkdir -p /root/.omf/trusted_roots
        omf_cert.rb --email root@$DOMAIN -o /root/.omf/trusted_roots/root.pem --duration 50000000 create_root
        omf_cert.rb -o /root/.omf/am.pem  --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+am --email am@$DOMAIN --resource-id amqp://am_controller@$XMPP_DOMAIN --resource-type am_controller --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/user_cert.pem --geni_uri URI:urn:publicid:IDN+$AM_SERVER_DOMAIN+user+root --email root@$DOMAIN --user root --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_user

        openssl rsa -in /root/.omf/am.pem -outform PEM -out /root/.omf/am.pkey
        openssl rsa -in /root/.omf/user_cert.pem -outform PEM -out /root/.omf/user_cert.pkey
        ##END OF CERTIFICATES CONFIGURATION

        echo "###############CONFIGURING OMF_SFA AS UPSTART SERVICE###############"
        cp init/omf-sfa.conf /etc/init/ && sed -i '/chdir \/root\/omf\/omf_sfa/c\chdir \/root\/omf_sfa' /etc/init/omf-sfa.conf
        #End of Broker installation
    fi
}

remove_broker() {
    stop omf-sfa
    rm -rf $OMF_SFA_HOME
    rm /etc/init/omf-sfa.conf
    rm -rf /root/.omf/*.pem
    rm -rf /root/.omf/*.pkey
    rm -rf /root/.omf/trusted_roots

    if [ $1 == "-y" ]; then
        remove_nitos_rcs --purge
    else
        echo "NITOS Testbed RCs will not work without Broker. Do you want to uninstall them too? (Y/n)"
        read option
        case $option in
            Y|y) remove_nitos_rcs --purge;;
            *) ;;
        esac
    fi
}

install_nitos_rcs() {
    if ! gem list nitos_testbed_rc -i; then
        #Start of NITOS Testbed RCs installation
        echo "###############INSTALLING NITOS TESTBED RCS###############"
        cd /root
        git clone -b amqp https://github.com/viniciusgb4/nitos_testbed_rc.git
        cd $NITOS_HOME
        gem build nitos_testbed_rc.gemspec
        gem install nitos_testbed_rc-2.0.5.gem

        install_ntrc

        ##START OF CERTIFICATES CONFIGURATION
        echo "###############CONFIGURING NITOS TESTBED RCS CERTIFICATES###############"
        omf_cert.rb -o /root/.omf/user_factory.pem --email user_factory@$DOMAIN --resource-type user_factory --resource-id amqp://user_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/cm_factory.pem --email cm_factory@$DOMAIN --resource-type cm_factory --resource-id amqp://cm_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        omf_cert.rb -o /root/.omf/frisbee_factory.pem --email frisbee_factory@$DOMAIN --resource-type frisbee_factory --resource-id amqp://frisbee_factory@$XMPP_DOMAIN --root /root/.omf/trusted_roots/root.pem --duration 50000000 create_resource
        cp -r /root/.omf/trusted_roots/ /etc/nitos_testbed_rc/
        ##END OF CERTIFICATES CONFIGURATION
        #End of NITOS Testbed RCs installation
        rm -rf $NITOS_HOME
    fi
}

remove_nitos_rcs() {
    stop ntrc
    gem uninstall nitos_testbed_rc -a -I --force -x

    if [ "$1" == "--purge" ]; then
        rm -rf /root/.omf/
    else
        rm -rf /root/.omf/etc
    fi

    rm -rf /etc/nitos_testbed_rc
    rm -rf /usr/local/bin/run_ntrc.sh
}

configure_testbed() {

    ##START OF - COPING CONFIGURATION FILES
    echo "###############COPYING CONFIGURATION FILES TO THE RIGHT PLACE###############"
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp
    cd $INSTALLER_HOME
    cp -r /tmp/testbed-files/* /
    ##END OF - COPING CONFIGURATION FILES

    #START OF PXE CONFIGURATION
    echo "###############PXE CONFIGURATION###############"
    ln -s /usr/lib/syslinux/pxelinux.0 /tftpboot/
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:23:46
    ln -s /tftpboot/pxelinux.cfg/pxeconfig /tftpboot/pxelinux.cfg/01-00:03:1d:0c:47:48

    cp /etc/hosts /etc/hosts.bkp
    cat /root/hosts >> /etc/hosts
    rm /root/hosts
    #END OF PXE CONFIGURATION
}

remove_testbed_configuration() {
    cp /etc/dnsmasq.conf.bkp /etc/dnsmasq.conf
    rm /etc/dnsmasq.d/testbed.conf
    rm -rf /root/omf-images
    rm -rf /root/ec-test
    rm -rf /tftpboot
}

start_broker() {
    echo "Executing omf_sfa"
    start omf-sfa
}

start_nitos_rcs() {
    echo "Executing NITOS Testbed RCs"
    start ntrc
}

insert_nodes() {
    /root/omf_sfa/bin/create_resource -t node -c /root/omf_sfa/bin/conf.yaml -i /root/resources.json
}

install_amqp_server() {
    apt-get install -y --force-yes rabbitmq-server
}

remove_amqp_server() {
    apt-get remove -y --force-yes --purge rabbitmq-server
}

download_baseline_image() {
    mkdir /root/omf-images
    wget https://www.dropbox.com/s/2bgqpebadxb8fgh/root-node-icarus1-05_07_2016_01%3A51.ndz?dl=0 -O /root/omf-images/baseline.ndz
}

install_oml2() {
    echo "deb http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list
    echo "deb-src http://download.opensuse.org/repositories/home:/cdwertmann:/oml/xUbuntu_14.04/ ./" >> /etc/apt/sources.list

    apt-get update
    apt-get install -y --force-yes oml2-server
}

remove_oml2() {
    apt-get remove -y --force-yes --purge oml2-server
}

#TODO remove configuration in /etc/hosts
#TODO remove omf_ec executable script. Note: use which to find it.
remove_testbed() {
    echo -n "Do you really want to remove all Testbed components? This will remove all configuration files too. (y/N)"
    read option
    case $option in
        Y|y) ;;
        N|n) exit ;;
        *) exit;;
    esac

    remove_nitos_rcs
    remove_broker -y
    remove_amqp_server
    remove_omf
    remove_oml2
    remove_testbed_configuration
}

install_testbed() {
    install_dependencies

    $INSTALLER_HOME/configure.sh

    install_omf
    install_amqp_server
    install_broker
    install_nitos_rcs
    configure_testbed

    service dnsmasq restart

    #########################START OF CREATE USER RABBITMQ#####################
    rabbitmqctl add_user testbed lab251
    rabbitmqctl set_permissions -p / testbed ".*" ".*" ".*"

    rabbitmqctl add_user cm_user lab251
    rabbitmqctl set_permissions -p / cm_user ".*" ".*" ".*"

    rabbitmqctl add_user frisbee_user lab251
    rabbitmqctl set_permissions -p / frisbee_user ".*" ".*" ".*"

    rabbitmqctl add_user script_user lab251
    rabbitmqctl set_permissions -p / script_user ".*" ".*" ".*"

    rabbitmqctl add_user user_proxy_user lab251
    rabbitmqctl set_permissions -p / user_proxy_user ".*" ".*" ".*"
    #########################END OF CREATE USER RABBITMQ#####################

    start_broker
    start_nitos_rcs

    echo "Waiting for services start up..."
    sleep 5s

    echo -n "Do you want to install the OML Server? (Y/n)"
    read option
    case $option in
        Y|y) install_oml2 ;;
        N|n) ;;
        *) install_oml2 ;;
    esac

    echo -n "Do you want to insert the resources into Broker? (Y/n)"
    read option
    case $option in
        Y|y) insert_nodes ;;
        N|n) ;;
        *) insert_nodes;;
    esac

    echo -n "Do you want to configure omf_ec on Icarus nodes? (Y/n)"
    read option
    case $option in
        Y|y) $INSTALLER_HOME/configure-icarus.sh ;;
        N|n) ;;
        *) $INSTALLER_HOME/configure-icarus.sh ;;
    esac

    echo -n "Do you want to download the baseline image for icarus nodes? (Y/n)"
    read option
    case $option in
        Y|y) download_baseline_image ;;
        N|n) exit ;;
        *) download_baseline_image;;
    esac
}

reinstall_testbed() {
    printMessage "REMOVING THE TESTBED"
    if [ -d "$OMF_SFA_HOME" ] || [ -d "/root/.omf" ]; then
        remove_testbed
    fi
    printMessage "INSTALLING THE TESTBED"
    install_testbed
}

main() {
    echo "------------------------------------------"
    echo "Options:"
    echo
    echo "1. Install Testbed"
    echo "2. Uninstall Testbed"
    echo "3. Reinstall Testbed"
    echo "4. Install only Broker"
    echo "5. Uninstall Broker"
    echo "6. Install only NITOS Testbed RCs"
    echo "7. Uninstall NITOS Testbed RCs"
    echo "8. Insert resources into Broker"
    echo "9. Download baseline.ndz"
    echo "10. Configure omf_rc on Icarus nodes"
    echo "11. Exit"
    echo
    echo -n "Choose an option..."
    read option
    case $option in
    1) install_testbed ;;
    2) remove_testbed ;;
    3) reinstall_testbed ;;
    4) install_broker ;;
    5) remove_broker ;;
    6) install_nitos_rcs ;;
    7) remove_nitos_rcs ;;
    8) insert_nodes ;;
    9) download_baseline_image ;;
    10) $INSTALLER_HOME/configure-icarus.sh ;;
    *) exit ;;
    esac
}

main