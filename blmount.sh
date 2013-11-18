#!/bin/bash
###############################################################################
# $Author: kapeller $
# $Date: 2010/11/23 08:47:08 $
# $Id: blmount,v 1.14 2010/11/23 08:47:08 kapeller Exp $
# $Name:  $
# $Revision: 1.14 $
###############################################################################
# Description:
# This script should be an easy to use wrapper to smbmount.
# Mounts e-account directories from the beamline filservers onto $HOME/slsbl
#
###############################################################################
#

uid=$(id -u)
egid=$(id -g)
fmask="0700"
dmask="0700"
verb=""
server=""
password=""
# Supported OSs: Linux, Darwin (Mac)
os=$(uname -s)
kmrel=$(uname -r | cut -c 1)

# Depending on the operating system, we use a different base directory for the mount point
case $os in
	Linux)	mountbase="${HOME}/slsbl";;
	Darwin)	mountbase="/Volumes";;
	*)	mountbase="/tmp"
esac

###############################################################################

testMacOSX() {
  if [ "$os" = "Darwin" -a "$kmrel" != "9" ]; then
    blsubnet=$(host $server | grep 'has address' | awk '{print $4}' | cut -d. -f 1,2,3)
    locnetinf=$(/sbin/ifconfig | grep 'inet 129.129.')
    if [[ $locnetinf != *$blsubnet* ]]; then
      echo "Warning: To use \"$(basename $0)\" outside of a beamline network,"
      echo "you need at least \"Mac OS X 10.5\" (Leopard)!"
      exit 1
    fi
  fi
}

usage() 
{
    echo
    echo "Usage: $(basename $0) [options] server account"
    echo 
    echo "       server = [x04sa, x05db, x09la, ...]"
    echo "       account = [public, e10001, e10002, e10003, ...]"
    echo
    echo "       Note: When specifying 'public' as the account name, only"
    echo "             the public directory of all e-accounts will be mounted."
    echo
    echo "       -v             # Be more verbosely"
    echo "       -d mount-dir   # Alternative mount location"
    echo "       -p password    # Command line password"
    echo "       -a account     # e.g. e10123"
    echo "       -s server      # Samba server"
    echo "       -r             # Print version"
    echo 
    echo "Example: blmount -a e10026 -s x06sa -d /tmp -p secret"
    echo 

    exit 1
}

version() {
   echo "\$Id: blmount,v 1.14 2010/11/23 08:47:08 kapeller Exp $"
   exit 0
}

has_mount() {
  retval=1
  md=$1
  if (mount -t smbfs,cifs | grep -q ${md}); then
    retval=0
    echo -e "\n$(tput bold)Existing mount found:$(tput sgr0) ${md}"
    echo "Use $(tput bold)'blumount -d ${md}'$(tput sgr0) to remove the mount!"
  fi
  return $retval
}

fix_acl() {
 # restrict access to top directory to owner only (or owner and group if we are on NFS) 
 # all mount points are below this directory. 
 _dir="$1"
 _me=$(id -nu)
 _fs=/usr/bin/fs  # AFS command to change ACLs

 [[ -d $_dir && -n "$_me" ]] || return 1

 _fstype="$(/usr/bin/stat -f -c %T $_dir)"
 if [[ $_dir == /afs/psi.ch/* && -x $_fs ]] # is on AFS ?
 then 
    _current_acls=$($_fs listacl $_dir | egrep -v ^"Normal |Access list" | tr -d " \n")
    _wanted_acls="system:administratorsrlidwka${_me}rlidwka"
    if [ "$_current_acls" != "$_wanted_acls" ]; then
      echo -n fixing afs acls for directory $_dir ... 
      $_fs setacl -dir $_dir -acl system:administrators all $_me all -clear
      _current_acls=$($_fs listacl $_dir | egrep -v ^"Normal |Access list" | tr -d " \n")
      if [ "$_current_acls" == "$_wanted_acls" ]; then
        echo " done"
        return 0
      else
        echo " FAILED"
        return 2
      fi
    fi
 elif [[ "$_fstype" == "nfs" ]]
 then
   # for mount.cifs to work we need group r-x rights.
   _current_acls=$(stat -c %a $_dir)
   _wanted_acls="750"
   if [ "$_current_acls" != "$_wanted_acls" ]; then
     echo fixing permissions for directory $_dir
     chmod $_wanted_acls $_dir || return 3
   fi
 else # probably local file system, ext2/ext3, can set minimal user-only permissions
   _current_acls=$(stat -c %a $_dir)
   _wanted_acls="700"
   if [ "$_current_acls" != "$_wanted_acls" ]; then
     echo fixing permissions for directory $_dir
     chmod $_wanted_acls $_dir || return 3
   fi
 fi # is on AFS ?
 
 return 0
} 

###############################################################################

[ $# -lt 1 ] && usage

while getopts "d:a:s:p:vhr" opt; do
   case $opt in
   d )  mountbase=${OPTARG};;
   s )  server=${OPTARG};;
   a )  eid=${OPTARG};;
   p )  password=${OPTARG};;
   v )  verb="YES";;
   r )  version ;;
   h )  usage ;;
   \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))

[ -z "$server" ] && server=$1
# 2010-11-23/Kapeller:
# blmount does also work on Macs outside of the beamline.
# However, there is an issue with password upper/lower case mismatch.
# Work around: tpye your password all in upper case on your Mac
#testMacOSX $server

# For bachward compatibility, we expect the second argument to be
# the UID, if not supplied by means of option '-a'
[ -z "$eid" ] && eid=$2

case $os in
  Linux) mountdir="${mountbase}/${server}/${eid}"
  # 2010-11-23/Kapeller:
  # fix_acl does not work for "Mac OS X" (Darwin) due to incompatible args of stat()
  fix_acl ${mountbase}
  ;;
  Darwin) mountdir="${mountbase}/${eid}";;
esac
#fix_acl ${mountbase}
mkdir -p ${mountdir}

if [ "${eid}" = "public" ]; then
  if (! has_mount ${mountdir}); then
    echo -e '\nMounting in progress, be patient ...'
    case $os in
      Linux)
        mntcmd="smbmount //${server}/${server}_public ${mountdir} -o password=\"\""
        smbmount //${server}/${server}_public ${mountdir} -o password=""
        ;;
      Darwin)
        mntcmd="mount -t smbfs //${eid}:@${server}/${server}_public ${mountdir}"
        ;;
    esac
    [ -n "$verb" ] && echo $mntcmd
    $mntcmd
  fi
else
  if (! has_mount ${mountdir}); then
    [ -z "$password" ] && read -p 'Password: ' -s -t 30 password
    echo -e '\nMounting in progress, be patient ...'
    case $os in
      Linux)
        #mntcmd="smbmount //${server}/${eid} ${mountdir} -o uid=${uid},gid=${egid},file_mode=${fmask},username=${eid},password=$password"
	mntcmd="mount -t cifs -o uid=${uid},gid=${egid},file_mode=${fmask},username=${eid},password=$password //${server}/${eid} ${mountdir}"
      echo $mntcmd
	  ;;
      Darwin)
        mntcmd="mount -t smbfs //${eid}:$password@${server}/${eid} ${mountdir}"
	echo mntcmd
        ;;
    esac
    [ -n "$verb" ] && echo $mntcmd
    $mntcmd
    if [ $? -eq 0 ]; then
      echo "Successfully mounted to: $(tput bold)${mountdir}$(tput sgr0)"
    else
      if [ "$os" == "Darwin" ]; then
        echo
        echo "==> Hint: Password problems on a Mac? Try entering your password all in upper case!"
      fi
    fi
  fi
fi

echo


### EOF
