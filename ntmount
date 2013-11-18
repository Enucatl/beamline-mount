#!/bin/bash
###############################################################################
# $Author: Silvia Peter $
# $Date: 20130610 $
# $Name:  $
# $Revision: 1.8 $
###############################################################################
# Description:
# This script should be an easy to use wrapper to smbmount.
# Mounts scratch directories onto $HOME/nt
#
###############################################################################
#
# $Log: ntmount,v $
###############################################################################
#
uid=$(id -u)
uidm=$(id -u)
egid=$(echo ${eid} | tr -d 'e')
verb=""
password=""

mountbase="${HOME}/nt";


###############################################################################


usage() 
{
    echo
    echo "Usage: $(basename $0) [options] -u username"
    echo 
    echo
    echo "       -v             # Be more verbosely"
    echo "       -u username    # Windows username"
    echo 
    echo "Example: ntmount -u peter_s"
    echo 
    exit 1
}

version() {
   echo "\$Id: ntmount for ubuntu, $"
   exit 0
}

has_mount() {
  retval=1
  md=$1
  if (mount -t smbfs | grep -q ${md}); then
    retval=0
    echo -e "\n$(tput bold)Existing mount found:$(tput sgr0) ${md}"
  fi
  return $retval
}

###############################################################################

[ $# -lt 0 ] && usage

while getopts "u:v:" opt; do
   case $opt in
   u )  uidm=${OPTARG};;
   p )  password=${OPTARG};;
   v )  verb="YES";;
   \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))

[ -z "$eid" ] && eid=$2
egid=$(echo ${eid} | tr -d 'e')

mountdir="${mountbase}/s/";

mkdir -p ${mountdir}

  if (! has_mount ${mountdir}); then
    [ -z "$password" ] && read -p 'Password: ' -s -t 30 password
    echo -e '\nMounting in progress, be patient ...'
        mntcmd="sudo mount -t cifs //scratch0/scratch ${mountdir} -o username=${uidm},password=$password,uid=${uid}"
    [ -n "$verb" ] && echo $mntcmd
    $mntcmd
    if [ $? -eq 0 ]; then
      echo "Successfully mounted to: $(tput bold)${mountdir}$(tput sgr0)"
    fi
  fi

echo

### EOF
