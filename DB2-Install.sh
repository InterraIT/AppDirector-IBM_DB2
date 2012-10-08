#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -e
export http_proxy=http://proxy.vmware.com:3128

################## INTERNAL PARAMETERS #########################
DOWNLOAD_URL="$download_url"
PORT_NUMBER="$port_number"
GROUP_NAME="$group_name"
INSTANCE_NAME="$instance_name"
INSTALLATION_DIR="$installation_dir"
INSTALLATION_TYPE="$installation_type"
SILENT_XML="/tmp/db2.rsp"
INSTALL_EDITION_ARRAY=(WORKGROUP_SERVER_EDITION ENTERPRISE_SERVER_EDITION EXPRESS_EDITION PERSONAL_EDITION)
DATABASE_NAME="$database_name"
DATABASE_USERNAME="$database_username"
DATABASE_PASSWORD="$database_password"
################################################################

# FUNTION TO CHECK ERROR
function check_response_code()
{
   if [ "$?" = "0" ]; then
      echo "Database Installed Successfully";
   else
      error_exit "Unsuccessful Installation. Error Code $?";
   fi
}

function check_error()
{
   if [ ! "$?" = "0" ]; then
      error_exit "$1";
   fi
}

################CREATING SILENT RESPONSE FILE###################
echo "Creating  reponse xml"
cat <<EOF> $SILENT_XML 
PROD = $INSTALLATION_TYPE
FILE = $INSTALLATION_DIR
LIC_AGREEMENT = ACCEPT
INSTALL_TYPE = TYPICAL
INSTANCE = DB2_INST
DB2_INST.NAME = $INSTANCE_NAME
DB2_INST.PASSWORD = $INSTANCE_NAME
DB2_INST.GROUP_NAME = $GROUP_NAME
DB2_INST.AUTOSTART = YES
DB2_INST.START_DURING_INSTALL = YES
DB2_INST.FENCED_USERNAME = db2user
DB2_INST.FENCED_GROUP_NAME = db2group
DB2_INST.PORT_NUMBER = $PORT_NUMBER
DATABASE = MY_DB
MY_DB.INSTANCE = DB2_INST 
MY_DB.DATABASE_NAME = $DATABASE_NAME
MY_DB.LOCATION = LOCAL
MY_DB.ALIAS = $DATABASE_NAME
MY_DB.USERNAME = $DATABASE_USERNAME
MY_DB.PASSWORD = $DATABASE_PASSWORD
EOF
################################################################

################INSTALLING IBM DB2##############################
cd /tmp
### Downloading tar ball
echo "Downloading the tar ball"
wget --output-document=installer.tar.gz $DOWNLOAD_URL
echo "Downloading the tar ball - DONE"

### Extracting tar ball
echo "Extracting the tar ball"
tar xvfz installer.tar.gz
echo "Extracting the tar ball - DONE"


### Installing DB2
if [ -f /etc/redhat-release ] ; then
   echo "RHEL / CENTOS OS"
   echo "Installing Pre-requistes"
   yum --nogpgcheck -y install libaio-devel
   check_error "ERROR WHILE LIBAIO-DEVEL PACKAGE"
   echo "Installing Pre-requistes - DONE"

   ### Creating Required Users and Groups
   echo "Creating Required Users and Groups"
   groupadd db2group
   useradd -g db2group -s /bin/bash -d /home/db2user db2user
   groupadd $GROUP_NAME
   useradd -g $GROUP_NAME -s /bin/bash -d /home/db2inst1 $INSTANCE_NAME
   echo "Creating Required Users and Groups - DONE"
   
   ### Installing DB2
   echo "Installing DB2"
   /tmp/server/db2setup -r $SILENT_XML
   echo "RESPONSE CODE $?"
   check_response_code "Error"
elif [ -f /etc/debian_version ] ; then
   echo "Ubuntu OS"
   
   apt-get -f -y install linux-firmware --fix-missing
   apt-get -f -y install libaio1 --fix-missing 

   ### Creating Required Users and Groups
   echo "Creating Required Users and Groups"
   groupadd db2group
   useradd -g db2group -m db2user
   groupadd $GROUP_NAME
   useradd -g $GROUP_NAME -m $INSTANCE_NAME
   echo "Creating Required Users and Groups - DONE"
   
   ### Installing DB2
   echo "Installing DB2"
   /tmp/server/db2setup -r $SILENT_XML  -f sysreq
   echo "RESPONSE CODE $?"
   check_response_code "Error"

elif [ -f /etc/SuSE-release ] ; then
   echo "SUSE OS"
   ### Creating Required Users and Groups
   echo "Creating Required Users and Groups"
   groupadd db2group
   useradd -g db2group -m db2user
   groupadd $GROUP_NAME
   useradd -g $GROUP_NAME -m $INSTANCE_NAME
   echo "Creating Required Users and Groups - DONE"
   
   ### Installing DB2
   echo "Installing DB2"
   /tmp/server/db2setup -r $SILENT_XML  -f sysreq
   echo "RESPONSE CODE $?"
   check_response_code "Error"
fi
####################################################################

########################LOGGING########################################
echo "Response File"
cat /tmp/db2.rsp

echo "DB2 Setup Log"
cat /tmp/db2setup.log
#######################################################################