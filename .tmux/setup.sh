#!/bin/bash

directory=$(pwd)

setup() {
    SETUP='
export PATH=/root/go/bin:$PATH'
    echo "$SETUP" >> ~/.bashrc
    eval "$SETUP"
}

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

osdetect(){
    OS=`lowercase \`uname\``
    KERNEL=`uname -r`
    MACH=`uname -m`

    if [ "{$OS}" == "windowsnt" ]; then
        OS=windows
    elif [ "{$OS}" == "darwin" ]; then
        OS=mac
    else
        OS=`uname`
        if [ "${OS}" = "SunOS" ] ; then
            OS=Solaris
            ARCH=`uname -p`
            OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
        elif [ "${OS}" = "AIX" ] ; then
            OSSTR="${OS} `oslevel` (`oslevel -r`)"
        elif [ "${OS}" = "Linux" ] ; then
            if [ -f /etc/redhat-release ] ; then
                DistroBasedOn='RedHat'
                DIST=`cat /etc/redhat-release |sed s/\ release.*//`
                PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
            elif [ -f /etc/SuSE-release ] ; then
                DistroBasedOn='SuSe'
                PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
                REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
            elif [ -f /etc/mandrake-release ] ; then
                DistroBasedOn='Mandrake'
                PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='Debian'
                if [ -f /etc/lsb-release ] ; then
                    DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
                    PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
                    REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
                elif [ -f /etc/debian_version ] ; then
                    REV=`cat /etc/debian_version| awk -F=  '{ split($0,a,"."); print a[1] }'`
                fi
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
            fi
            OS=`lowercase $OS`
            DistroBasedOn=`lowercase $DistroBasedOn`
            export OS
            export DIST
            export DistroBasedOn
            export PSUEDONAME
            export REV
            export KERNEL
            export MACH
        fi

    fi
}

osdetect

echo "$PSUEDONAME"
echo "$DIST"

if [[ "$DistroBasedOn" == "debian" ]]; then
    apt update
    apt install gnupg sudo
    if [[ "$REV" == "7" ]]; then
        echo 'deb http://inverse.ca/downloads/PacketFence/debian wheezy wheezy' | sudo tee /etc/apt/sources.list.d/packetfence.list
    elif [[ "$REV" == "8" ]]; then
        echo 'deb http://inverse.ca/downloads/PacketFence/debian jessie jessie' | sudo tee /etc/apt/sources.list.d/packetfence.list
    elif [[ "$REV" == "9" ]]; then
        echo 'deb http://inverse.ca/downloads/PacketFence/debian stretch stretch' | sudo tee /etc/apt/sources.list.d/packetfence.list
    else
	echo 'deb http://inverse.ca/downloads/PacketFence/debian/11.2 bullseye bullseye' | sudo tee /etc/apt/sources.list.d/packetfence.list
    fi
    sudo wget -q -O - https://inverse.ca/downloads/GPG_PUBLIC_KEY | sudo apt-key    add - 
    #sudo wget -O - https://inverse.ca/downloads/GPG_PUBLIC_KEY | sudo apt-key add -
    if [ ! -f ~/.tmux.conf ]; then
        read -r -p $'\e[31mWould you like to install tmux? (Yes / No)\e[0m:' tmux
        case $tmux in
            [yY][eE][sS]|[yY])
                sudo apt-get update
                sudo apt-get -y install git tmux
                curl --insecure https://support.inverse.ca/~fdurand/tmux.conf > ~/.tmux.conf
                git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
                read -r -d '' TMUX << EOM
function ssht () {
    ssh -t $@ "tmux attach || tmux new"
}
EOM
                echo "$TMUX" >> ~/.bashrc
                ;;
            *)
                ;;
        esac
    else
        read -r -p $'\e[31mWould you like to update tmux config? (Yes / No)\e[0m:' tmux
        case $tmux in
            [yY][eE][sS]|[yY])
                curl --insecure https://support.inverse.ca/~fdurand/tmux.conf > ~/.tmux.conf
                ;;
            *)
                ;;
         esac
    fi
    if [ -f /usr/local/pf/conf/pf.conf ]; then
        #read -r -p $'\e[31mWould you like to install xtrabackup? (Yes / No)\e[0m:' xtrabackup
        #case $xtrabackup in
        #    [yY][eE][sS]|[yY])
        #        sudo wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
        #        sudo dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
        #        sudo apt-get update
        #        sudo apt-get -y install percona-xtrabackup-24
        #        sudo sed -i 's/PERCONA_XTRABACKUP_INSTALLED=0/PERCONA_XTRABACKUP_INSTALLED=1/g' /usr/local/pf/addons/database-backup-and-maintenance.sh
        #        sudo iptables -F
        #        sudo iptables -X
        #        sudo iptables -t nat -F
        #        sudo iptables -t nat -X
        #        sudo iptables -t mangle -F
        #        sudo iptables -t mangle -X
        #        sudo iptables -P INPUT ACCEPT
        #        sudo iptables -P FORWARD ACCEPT
        #        sudo iptables -P OUTPUT ACCEPT
        #    ;;
        #*)
        #    ;;
        #esac
        read -r -p $'\e[31mWould you like to configure the cluster (Yes / No)\e[0m:' cluster
        case $cluster in
            [yY][eE][sS]|[yY])
                curl --insecure https://support.inverse.ca/~fdurand/clusterinit.pm > ~/clusterinit.pm
                perl ~/clusterinit.pm --distrib=debian
            ;;
        *)
            ;;
        esac
    fi
    read -r -p $'\e[31mWould you like to install sysdig? (Yes / No)\e[1m:' sysdig
    case $sysdig in
        [yY][eE][sS]|[yY])
            sudo curl --insecure -s https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public | apt-key add -
            sudo curl --insecure -s -o /etc/apt/sources.list.d/draios.list http://download.draios.com/stable/deb/draios.list
            sudo apt-get update
            sudo apt-get -y install linux-headers-$(uname -r)
            sudo apt-get -y install sysdig
            ;;
        *)
            ;;
    esac
    sudo apt-get -y install tshark lsof sysstat socat pssh iotop vim python3-psutil python3-future
    curl --insecure curl --insecure https://support.inverse.ca/~fdurand/glances_3.1.5-1_all.deb > ~/glances_3.1.5-1_all.deb
    dpkg -i ~/glances_3.1.5-1_all.deb
    read -r -p $'\e[31mWould you like to install haproxyctl? (Yes / No)\e[0m:' haproxyctl
    case $haproxyctl in
        [yY][eE][sS]|[yY])
            sudo apt-get -y install git curl sed
            curl --insecure https://raw.githubusercontent.com/inverse-inc/packetfence/devel/addons/dev-helpers/setup-go-env.sh > ~/setup-go-env.sh
            chmod +x ~/setup-go-env.sh
            GOVERSION=go1.16 GO_REPO=~/go ~/setup-go-env.sh
            setup
            source ~/.bashrc
            go get github.com/cxfcxf/haproxyctl
            if ! grep -q "haproxyadmin" ~/.bashrc
            then
                echo "alias haproxyadmin='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-admin.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            if ! grep -q "haproxyportal" ~/.bashrc
            then
                echo "alias haproxyportal='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-portal.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            if ! grep -q "haproxydb" ~/.bashrc
            then
                echo "alias haproxydb='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-db.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            #MGMTIP=$(perl -I/usr/local/pf/lib -I/usr/local/pf/lib_perl/lib/perl5/ -Mpf::config -e 'use pf::config qw ($management_network); print defined( $management_network->tag(vip) ) ? $management_network->tag(vip) : $management_network->tag(ip)')        
            #curl --insecure https://support.inverse.ca/~fdurand/config.toml > ~/config.toml
	    #sed -i "s/MGMTIP/$MGMTIP/g" ./config.toml
            #sudo apt-get -y install ruby
            #sudo gem install haproxyctl
            ;;
        *)
            ;;
    esac
    if ! grep -q "HAPROXY_CONFIG" ~/.bashrc
    then
        echo "export HAPROXY_CONFIG=/usr/local/pf/var/conf/haproxy-db.conf" >> ~/.bashrc
    fi
elif [[ "$DistroBasedOn" == "redhat" ]]; then
    if [[ $REV -gt 8 ]]; then
    #    sudo yum localinstall http://packetfence.org/downloads/PacketFence/RHEL8/packetfence-release-11.0.el8.noarch.rpm -y
        sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
        sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel.repo
    fi
    sudo yum clean all
    sudo yum -y install pssh mailx wireshark lsof socat iotop glances vim autossh --enablerepo=epel
    if [ ! -f ~/.tmux.conf ]; then
        read -r -p $'\e[31mWould you like to install tmux? (Yes / No)\e[0m:' tmux
        case $tmux in
            [yY][eE][sS]|[yY])
                sudo yum -y install tmux git --enablerepo=packetfence-extra
                curl --insecure https://support.inverse.ca/~fdurand/tmux.conf > ~/.tmux.conf
                git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
                read -r -d '' TMUX << EOM
function ssht () {
    ssh -t $@ "tmux attach || tmux new"
}
EOM
                echo "$TMUX" >> ~/.bashrc
                ;;
            *)
                ;;
        esac
    else
        read -r -p $'\e[31mWould you like to update tmux config? (Yes / No)\e[0m:' tmux
        case $tmux in
            [yY][eE][sS]|[yY])
                curl --insecure https://support.inverse.ca/~fdurand/tmux.conf > ~/.tmux.conf
                ;;
            *)
                ;;
         esac

    fi
    if [ -f /usr/local/pf/conf/pf.conf ]; then
        read -r -p $'\e[31mWould you like to install xtrabackup? (Yes / No)\e[0m:' xtrabackup
        #case $xtrabackup in
        #    [yY][eE][sS]|[yY])
        #        sudo yum -y install https://repo.percona.com/yum/release/7/RPMS/noarch/percona-release-0.1-3.noarch.rpm
        #        sudo sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/percona-release.repo
        #        sudo yum -y install percona-xtrabackup socat --enablerepo=percona-release-x86_64,percona-release-noarch

        #        sudo sed -i 's/PERCONA_XTRABACKUP_INSTALLED=0/PERCONA_XTRABACKUP_INSTALLED=1/g' /usr/local/pf/addons/backup-and-maintenance.sh
        #        sudo iptables -F
        #        sudo iptables -X
        #        sudo iptables -t nat -F
        #        sudo iptables -t nat -X
        #        sudo iptables -t mangle -F
        #        sudo iptables -t mangle -X
        #        sudo iptables -P INPUT ACCEPT
        #        sudo iptables -P FORWARD ACCEPT
        #        sudo iptables -P OUTPUT ACCEPT
        #    ;;
        #*)
        #    ;;
        #esac
        read -r -p $'\e[31mWould you like to configure the cluster (Yes / No)\e[0m:' cluster
        case $cluster in
            [yY][eE][sS]|[yY])
                curl --insecure https://support.inverse.ca/~fdurand/clusterinit.pm > ~/clusterinit.pm
                perl ~/clusterinit.pm --distrib=RHEL
            ;;
        *)
            ;;
        esac
    fi
    if ! grep -q "HAPROXY_CONFIG" ~/.bashrc
    then
        echo "export HAPROXY_CONFIG=/usr/local/pf/var/conf/haproxy-db.conf" >> ~/.bashrc
    fi
    read -r -p $'\e[31mWould you like to install sysdig? (Yes / No)\e[0m:' sysdig
    case $sysdig in
        [yY][eE][sS]|[yY])
            sudo rpm --import https://s3.amazonaws.com/download.draios.com/DRAIOS-GPG-KEY.public
            sudo curl --insecure -s -o /etc/yum.repos.d/draios.repo http://download.draios.com/stable/rpm/draios.repo
            sudo yum -y install kernel-devel-$(uname -r)
            sudo yum -y install sysdig --enablerepo=epel
            ;;
        *)
            ;;
    esac
    read -r -p $'\e[31mWould you like to install haproxyctl? (Yes / No)\e[0m:' haproxyctl
    case $haproxyctl in
        [yY][eE][sS]|[yY])
            sudo yum -y install git curl sed
            curl --insecure https://raw.githubusercontent.com/inverse-inc/packetfence/devel/addons/dev-helpers/setup-go-env.sh > ~/setup-go-env.sh
            chmod +x ~/setup-go-env.sh
            GOVERSION=go1.16 GO_REPO=~/go ~/setup-go-env.sh
            setup
            source ~/.bashrc
            go get github.com/cxfcxf/haproxyctl
            if ! grep -q "haproxyadmin" ~/.bashrc
            then
                echo "alias haproxyadmin='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-admin.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            if ! grep -q "haproxyportal" ~/.bashrc
            then
                echo "alias haproxyportal='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-portal.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            if ! grep -q "haproxydb" ~/.bashrc
            then
                echo "alias haproxydb='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-db.conf -action=\"showhealth\"'" >> ~/.bashrc
            fi
            #MGMTIP=$(perl -I/usr/local/pf/lib -I/usr/local/pf/lib_perl/lib/perl5/ -Mpf::config -e 'use pf::config qw ($management_network); print defined( $management_network->tag(vip) ) ? $management_network->tag(vip) : $management_network->tag(ip)')
            #curl --insecure https://support.inverse.ca/~fdurand/config.toml > ~/config.toml
            #sed -i "s/MGMTIP/$MGMTIP/g" ./config.toml
            #sudo yum -y install rubygems
            #sudo gem install haproxyctl
            ;;
        *)
            ;;
    esac
fi

read -r -p $'\e[31mWould you like to install the reverse tunnel config ? (Yes / No)\e[0m:' response
case $response in
    [yY][eE][sS]|[yY])
        #if [[ "$DistroBasedOn" == "debian" ]]; then
        #    sudo apt-get install monit uuid-runtime
        #    sudo sed -i -e 's/include.*\*$//g' /etc/monit/monitrc && echo "include /etc/monit/conf.d/*.conf" >> /etc/monit/monitrc
        #elif [[ "$DistroBasedOn" == "redhat" ]]; then
        #    sudo yum -y install monit uuid mailx --enablerepo=packetfence-extra -y
        #    sed -i -e 's/^include.*//g' /etc/monit.conf && echo "include /etc/monit.d/*.conf" >> /etc/monit.conf
        #    sed -i -e 's/^include.*//g' /etc/monitrc && echo "include /etc/monit.d/*.conf" >> /etc/monitrc
        #fi
        #sudo gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E3A28334
        #sudo curl --insecure -s http://inverse.ca/downloads/PacketFence/monitoring-scripts/v1/monit.tgz -o /tmp/monit.tgz
        #sudo tar xzvf /tmp/monit.tgz -C /tmp/
        #mv /usr/local/pf/addons/monit /usr/local/pf/addons/monit.old ; mv /tmp/monit /usr/local/pf/addons/
        #read -r -p $'\e[32memail\e[0m:' email
        #read -r -p $'\e[32msubject\e[0m:' subject
        #read -r -p $'\e[32mConfiguration (packetfence,portsec,drbd,active-active,os-winbind,os-checks)\e[0m:' config
        #/usr/local/pf/addons/monit/monit_build_configuration.pl ${email} ${subject} ${config}
        #/usr/local/pf/addons/monit/monitoring-scripts/update.sh
        #/usr/local/pf/addons/monit/monitoring-scripts/run-all.sh
        sudo curl --insecure https://support.inverse.ca/~fdurand/autossh.sh | sudo tee /root/autossh.sh
        chmod +x /root/autossh.sh
        echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqJKb+V1x6ods1TyNbAjXIfG9uKezyzzPx1oT/Lhg43dilR8rHqksHBVPymaHkDtuGpAB1WkqRoHk33IJNhnprWZbonldVrg0M1iauvG8pMdSZ0r5y/XwhPbXW5ZuDRo05gLX4/Q8rW86Dl+Z87BPocp/fQX7sD61+jmPj6sSEvLGG7xUVVjAEuV4UA0XTVvtgLaFhLhNWPnJBo63vvDPlsIiupVrMEwvIhKYpmrBZYn1QGJ7wVP9GMdNPSxni+Z3miUQSIUsP+x4tVGW3tcqFZfCYj5CSGEMFMBCQA58XZ+jO8pxMUsBHBXnt5+g7E/G3CpCUVQtc3XDwCoMTVLZl oeufdure@gmail.com' >> ~/.ssh/authorized_keys
        mkdir -p /etc/monit.d/
        sudo curl --insecure https://support.inverse.ca/~fdurand/60_custom.conf | sudo tee /etc/monit.d/60_custom.conf
        ;;
    *)
        ;;
esac

read -r -p $'\e[31mWould you like to install optimized sysctl.conf? (Yes / No)\e[0m:' sysctl
case $sysctl in
    [yY][eE][sS]|[yY])
        curl --insecure https://support.inverse.ca/~fdurand/sysctl.conf | sudo tee /etc/sysctl.conf
        sudo sysctl -p
        echo 1 >/sys/kernel/mm/ksm/run
        echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs
        ;;
    *)
        ;;
esac

sudo find /tmp/ -maxdepth 1 -type f -user pf -exec sudo rm -f {} \;

# if [ -f /usr/local/pf/conf/pf.conf ]; then
#     sudo find /usr/local/pf/logs/httpd.*.gz -mtime +7 -print0 |  xargs -0r sudo rm -f
#     sudo find /usr/local/pf/logs/* -mtime +90 -print0 |  xargs -0r sudo rm -f
# fi

#read -r -p $'\e[31mWould you like to add aliases? (Yes / No)\e[0m:' aliases
#case $aliases in
#    [yY][eE][sS]|[yY])
#        if ! grep -q "haproxyadmin" ~/.bashrc
#        then
#            echo "alias haproxyadmin='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-admin.conf -action=\"showbackend\"'" >> ~/.bashrc
#        fi
#        if ! grep -q "haproxyportal" ~/.bashrc
#            then
#            echo "alias haproxyportal='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-portal.conf -action=\"showbackend\"'" >> ~/.bashrc
#        fi
#        if ! grep -q "haproxydb" ~/.bashrc
#            then
#            echo "alias haproxydb='/root/go/bin/haproxyctl -f /usr/local/pf/var/conf/haproxy-db.conf -action=\"showbackend\"'" >> ~/.bashrc
#        fi
#        ;;
#    *)
#        ;;
#esac

