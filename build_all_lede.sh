#!/bin/bash

DEFAULT_SITE_URL="https://github.com/ffdo/site-ffdo-l2tp.git"
DEFAULT_GLUON_URL="https://github.com/freifunk-gluon/gluon.git"
DEFAULT_BUILD_OUTPUT_DIR=${BUILD_OUTPUT_DIR_DOCKER_ENV:-'../build/'}
DEFAULT_GLUON_OUTPUTDIR_PREFIX=$DEFAULT_BUILD_OUTPUT_DIR/${BUILD_IMAGE_DIR_PREFIX_DOCKER_ENV/:-'data/images.ffdo.de'}
DEFAULT_GLUON_SITEDIR=${BUILD_SITE_DIR_DOCKER_ENV:-$(dirname $(pwd))'/site/'}
DEFAULT_GLUON_DIR=${BUILD_GLUON_DIR_DOCKER_ENV:-'../gluon/'}

if [ -f HIPCHAT_AUTH_TOKEN ]; then
	HIPCHAT_NOTIFY_URL="https://hc.infrastruktur.ms/v2/room/34/notification?auth_token=$(cat HIPCHAT_AUTH_TOKEN)" # HIPCHAT_AUTH_TOKEN Muss als Datei im gleichen Ordner wie build_all.sh liegen und den AuthToken für HipChat enthalten.
else
	HIPCHAT_NOTIFY_URL=""
fi
if [ -f $TELEGRAM_AUTH_TOKEN ]; then
	TELEGRAM_NOTIFY_URL="https://api.telegram.org/bot$(cat $TELEGRAM_AUTH_TOKEN)/sendMessage" 
	TELEGRAM_NOTIFY_CHATID=${TELEGRAM_NOTIFY_CHATID_DOCKER_ENV:-''}
else
	TELEGRAM_NOTIFY_URL=""
	TELEGRAM_NOTIFY_CHATID=""
fi

GLUON_VERSION=${GLUON_TAG_DOCKER_ENV:-''}
VERSION=${GLUON_RELEASE_DOCKER_ENV:-''}
TARGETS_TO_BUILD=""
CUR_BUILD_TARGET=""
CORES=""
MAKE_OPTS=""
DOMAINS_TO_BUILD=""
CUR_BUILD_DOMAIN=""
SITE_URL=""
GLUON_URL=""
BROKEN=""
RETRIES=""
SKIP_GLUON_PREBUILD_ACTIONS=""
FORCE_DIR_CLEAN=""
BUILD_OUTPUT_DIR=""
imagedir=""
modulesdir=""

function expand_relativ_path () {
	echo ${1/../$(dirname $(pwd))}
}

function set_arguments_not_passed () {
	GLUON_GLUONDIR=${GLUON_GLUONDIR:-$DEFAULT_GLUON_DIR}
	GLUON_SITEDIR=${GLUON_SITEDIR:-$DEFAULT_GLUON_SITEDIR}
	GLUON_OUTPUTDIR_PREFIX=${GLUON_OUTPUTDIR_PREFIX:-$DEFAULT_GLUON_OUTPUTDIR_PREFIX}
#	CORES=${CORES:-$(grep -ic 'model name' /proc/cpuinfo)}
	CORES=${CORES:-$(expr $(nproc) + 1)}
	SITE_URL=${SITE_URL:-$DEFAULT_SITE_URL}
	GLUON_URL=${GLUON_URL:-$DEFAULT_GLUON_URL}
	RETRIES=${RETRIES:-1}
	SKIP_GLUON_PREBUILD_ACTIONS=${SKIP_GLUON_PREBUILD_ACTIONS:-0}
	BUILD_OUTPUT_DIR=${DEFAULT_BUILD_OUTPUT_DIR}

	GLUON_OUTPUTDIR_PREFIX=$(expand_relativ_path "$GLUON_OUTPUTDIR_PREFIX")
	BUILD_OUTPUT_DIR=$(expand_relativ_path "$BUILD_OUTPUT_DIR")
	GLUON_GLUONDIR=$(expand_relativ_path "$GLUON_GLUONDIR")
	GLUON_SITEDIR=$(expand_relativ_path "$GLUON_SITEDIR")
	GLUON_IMAGEDIR=$(expand_relativ_path "$GLUON_IMAGEDIR")
	FORCE_DIR_CLEAN=${FORCE_DIR_CLEAN:-0}
}

function split_value_from_argument () {
	if [[ "${1:1:1}" == '-' ]]
	then
	       	if [[ "$1" =~ '=' ]]
		then
			echo ${1##*=}
		else
			echo $2
			return 1
		fi
	else
		if [[ "${#1}" == 2 ]]
		then
			echo $2
			return 1
		else
			echo ${1:2}
		fi
	fi
	return 0
}

function notify () {
	COLOR=$1
	MESSAGE=$2
	NOTIFY=$3
	NC='\033[0m' # No Color
	case "$COLOR" in 
		red)
			CCODE="\033[31m"
			;;
		yellow)
			CCODE="\093[33m"
			;;
		purple)
			CCODE="\095[35m" # ok, bright magenta. Near enough
			;;
		green)
			CCODE="\033[32m"
			;;
		*)
			CCODE=""
			NC=""
			;;
	esac
	echo -e "${CCODE}${MESSAGE}${NC}"
	if [ ! -z "$HIPCHAT_NOTIFY_URL" ]; then
		curl -d '{"color":"'"$COLOR"'","message":"'"$(hostname) --> $MESSAGE"'","notify":"'"$NOTIFY"'","message_format":"text"}' -H 'Content-Type: application/json' $HIPCHAT_NOTIFY_URL
	fi
	if [ ! -z "$TELEGRAM_NOTIFY_URL" ]; then
        curl --max-time 10 -s -d "chat_id=$TELEGRAM_NOTIFY_CHATID&text=$MESSAGE" $TELEGRAM_NOTIFY_URL &>/dev/null
    fi
}

function enable_debugging () {
	set -x
}

function add_domain_to_buildprocess () {
	DOMAINS_TO_BUILD="$DOMAINS_TO_BUILD $1"
}

function add_target_to_buildprocess () {
	TARGETS_TO_BUILD="$TARGETS_TO_BUILD $1"
}

function process_arguments () {
	while [[ $# -gt 0 ]]
	do
		arg=$1
		if [[ "${1:0:1}" == "-" ]]
		then
			value=`split_value_from_argument $1 $2`
			if [[ $? == 1 ]] 
			then
				shift
			fi
		else
			value=$1
		fi
		case "$arg" in
			-j*|--cores*)
				if [[ $value =~ ^-?[0-9]+$ ]]
				then
					CORES=$value
				else
					echo "Number of cores is not an integer. Aborting."
					echo
					display_usage
				fi
				shift
				;;
			-g*|--gluon-dir*)
				GLUON_GLUONDIR=$value
				shift
				;;
			-s*|--site-dir*)
				GLUON_SITEDIR=$value
				shift
				;;
			-o*|--output-prefix*)
				GLUON_OUTPUTDIR_PREFIX=$value
				shift
				;;
			--gluon-url*)
				GLUON_URL=$value
				shift
				;;
			--site-url*)
				SITE_URL=$value
				shift
				;;
			-D|--enable-debugging)
				enable_debugging
				;;
			-f|--force-dir-clean)
				FORCE_DIR_CLEAN=1
				;;
			-B|--enable-broken)
				BROKEN="BROKEN=1"
				;;
			-S|--skip-gluon-prebuilds)
				SKIP_GLUON_PREBUILD_ACTIONS=1
				;;
			-d*|--domain*)
				add_domain_to_buildprocess $value
				shift
				;;
			-t*|--target*)
				add_target_to_buildprocess $value
				shift
				;;
			-f*|--force-retries*)
				if [[ $value =~ ^-?[0-9]+$ ]]
				then
					RETRIES=$value
				else
					echo "Number of retries is not an integer. Aborting."
					echo
					display_usage
				fi
				shift
				;;
			*)
				if [[ $GLUON_VERSION == "" ]]
				then
					GLUON_VERSION=$value
				elif [[ $VERSION == "" ]]
				then
					VERSION=$value
				else
					echo "Unparsable parameter. Aborting."
					echo
					display_usage
				fi
				shift
				;;
		esac
	done
	if [[ $GLUON_VERSION == "" || $VERSION == "" ]]
	then
		display_usage
	fi
	set_arguments_not_passed
}

function build_make_opts () {

	MAKE_OPTS="-C $GLUON_GLUONDIR GLUON_RELEASE=$GLUON_VERSION+$VERSION GLUON_SITEDIR=$GLUON_SITEDIR V=s $BROKEN FORCE_UNSAFE_CONFIGURE=1"
}

function is_git_repo () {
	git -C "$1" status 2&> /dev/null
	if [ $? != 0 ]
	then
		echo "The folder \"$1\" is not a valid git repository, delete it or select another destination and restart the script."
		exit 1
	fi
	return 0
}

function display_usage () {
echo 'Usage: $0 [PARAMETERS] GLUON_RELEASE_TAG VERSION_NUMBER

Parameters:

All parameters can be set in one of the following ways: -e <value>, -e<value>, --example <value>, --exmaple==<value>

	-j --cores: Number of cores to use. If left empty, all cores will be used.

	-g --gluon-dir: Path to Gluon-Git-Folder. Default is "../gluon".
	-s --site-dir: Path to the site config. Default is "../site".
	-o --output-prefix: Prefix for output folder, default is "/var/www/html".
	--gluon-url: URL to Gluon repository, default is "https://github.com/freifunk-gluon/gluon.git".
	--site-url: URL to the site configuration. Default is site-ffdo-l2tp of Freifunk Dortmund.
	-D --enable-debugging: Enables debugging by setting "set -x". This must be the first parameter, if you want to debug the parameter parsing.
	-B --enable-broken: Enable the building of broken targets and broken images.
	-S --skip-gluon-prebuilds: Skip make dirclean of Gluon folder. 
	-d --domain: Branches of your site-Git-repository to build. If left empty, all Domäne-XX will be build. This parameter can be used multiple times or you can set multiple branches at once, seperated by space and in quotes: "branch1 branch2 branch3".
	-t*|--target: Targets to build. If left empty, all targets will be build. If broken is set, even those will be build. This parameter can be used multiple times or you can set multiple targets at once, seperated by space and in quotes: "target1 target2 target3".
	-f --force-dir-clean: Force a make dir clean after each target.


Please report issues here: 
	https://github.com/ffdo/site-ffdo-l2tp/issues
	https://github.com/FreiFunkMuenster/tools/issues

License: GPLv3, Author: Matthias Walther'
	exit 1
}

running_in_docker () {
  (awk -F/ '$2 == "docker"' /proc/self/cgroup | read non_empty_input)
}

function is_folder () {
	[[ -d $1 ]] && return 0 || return 1
}

function git_fetch () {
	git -C "$1" fetch
}

function git_checkout () {
	command="git -C \"$1\" checkout $2"
	try_execution_x_times $RETRIES "$command"
}

function git_pull () {
	git -C "$1" pull
}

function prepare_repo () {
	if is_folder "$1" && is_git_repo "$1"
	then
		git_fetch "$1"
	else
		git clone $2 "$1"
	fi
}

function force_dir_clean () {
	command="make dirclean $MAKE_OPTS"
	try_execution_x_times $RETRIES "$command"
}

function gluon_prepare_buildprocess () {
	command="make update ${MAKE_OPTS}"
	try_execution_x_times $RETRIES "$command"
	if [[ $FORCE_DIR_CLEAN=="1" ]]
	then
		force_dir_clean
	fi
	check_targets
	for target in $TARGETS_TO_BUILD
	do
		command="make clean $MAKE_OPTS -j$CORES GLUON_TARGET=$target GLUON_IMAGEDIR=$imagedir"
		try_execution_x_times $RETRIES "$command"
	done
	mkdir -p "$GLUON_GLUONDIR/tmp"
	mkdir tmp
}

function get_all_targets_from_gluon_repo () {
	echo `make $MAKE_OPTS GLUON_TARGET= 2> /dev/null |grep -v 'Please\|make\|Makefile'|sed -e 's/.* \* //g'`
}

function check_targets () {
	if [[ $TARGETS_TO_BUILD == "" ]]
	then
		if [[ $GLUON_TARGETS_DOCKER_ENV == "" ]]
		then
			TARGETS_TO_BUILD=$(get_all_targets_from_gluon_repo)
		else
			TARGETS_TO_BUILD=$GLUON_TARGETS_DOCKER_ENV
		fi
	fi
}

function get_all_domains_from_site_repo () {
	echo `git -C "$GLUON_SITEDIR" branch -a|grep -v HEAD|grep origin/Domäne| sed -e 's/.*\/Domäne/Domäne/'`
}

function create_checksumfile_in_dir () {
	chks_dir=$(expand_relativ_path "$1")
	if is_folder "$chks_dir"
	then 
		echo "$CUR_BUILD_DOMAIN: Creating SHA512 sums in: "$(basename "$chks_dir")
		MYPWD=$(pwd)
		cd "$chks_dir"
		sha512sum * > ./sha512sum.txt
		cd $MYPWD
	else 
		echo "Creating SHA512 sums: Directory $chks_dir does not exist."
	fi
}

function check_domains () {
	if [[ $DOMAINS_TO_BUILD == "" ]]
	then
		if [[ $DOMAINS_TO_BUILD_DOCKER_ENV == "" ]]
		then
			DOMAINS_TO_BUILD=$(get_all_domains_from_site_repo)
		else 
			DOMAINS_TO_BUILD=$DOMAINS_TO_BUILD_DOCKER_ENV
		fi
	fi
}

function try_execution_x_times () {
	tries_left=$1
	shift
	return_value=1
	while [[ $return_value != 0 && $tries_left -gt 0 ]]
	do
		let tries_left-=1
		echo "$@" | bash
		return_value=$?
	done
	if [[ ! $return_value == 0 ]]
	then
		notify "red" "Build abgebrochen." true
		echo "Something went wrong. Aborting."
		exit 1
	fi
}

function build_target_for_domaene () {
	command="make $MAKE_OPTS -j$CORES GLUON_BRANCH=stable GLUON_TARGET=$1 GLUON_IMAGEDIR=\"$imagedir\""
	try_execution_x_times $RETRIES "$command"
}

function make_manifests () {
	make manifest $MAKE_OPTS GLUON_BRANCH=experimental GLUON_PRIORITY=0 GLUON_IMAGEDIR="$imagedir"
	make manifest $MAKE_OPTS GLUON_BRANCH=beta GLUON_PRIORITY=0 GLUON_IMAGEDIR="$imagedir"
	make manifest $MAKE_OPTS GLUON_BRANCH=stable GLUON_PRIORITY=0 GLUON_IMAGEDIR="$imagedir"
}


function build_selected_targets_for_domaene () {
	prefix=`echo $1|sed -e 's/Domäne-/domaene/'`
	imagedir="$GLUON_OUTPUTDIR_PREFIX"/"$prefix"/releases/$VERSION/images
	modulesdir="$GLUON_OUTPUTDIR_PREFIX"/"$prefix"/releases/$VERSION/modules
	mkdir -p "$imagedir"
#	mkdir -p "$modulesdir"
	git_checkout "$GLUON_SITEDIR" $1
	git_pull "$GLUON_SITEDIR"
	
	for CUR_BUILD_TARGET in $TARGETS_TO_BUILD
	do
		if [[ $DO_CLEAN_BEFORE_BUILD == "1" ]]
		then
			notify "yellow" "$CUR_BUILD_DOMAIN Target $CUR_BUILD_TARGET säubern." false
			make clean $MAKE_OPTS GLUON_BRANCH=stable GLUON_TARGET=$CUR_BUILD_TARGET 
		fi
		notify "yellow" "$CUR_BUILD_DOMAIN Target $CUR_BUILD_TARGET gestartet." false
		build_target_for_domaene $CUR_BUILD_TARGET
		notify "yellow" "$CUR_BUILD_DOMAIN Target $CUR_BUILD_TARGET fertig." false
	done
	
	create_checksumfile_in_dir "$imagedir"/factory
	create_checksumfile_in_dir "$imagedir"/sysupgrade
# TODO:
#   split target name into "base - variation": 'x86-64';
#   use them as subfolder names.
#	create_checksumfile_in_dir "$modulesdir"/
	make_manifests
}

function build_selected_domains_and_selected_targets () {
	DO_CLEAN_BEFORE_BUILD=0
	for CUR_BUILD_DOMAIN in $DOMAINS_TO_BUILD
	do
		notify "purple" "$CUR_BUILD_DOMAIN gestartet." false
		build_selected_targets_for_domaene $CUR_BUILD_DOMAIN
		notify "purple" "$CUR_BUILD_DOMAIN fertig." false
		DO_CLEAN_BEFORE_BUILD=0
	done
}


process_arguments "$@"
notify "green" "Build $GLUON_VERSION+$VERSION gestartet." true
if running_in_docker 
then 
	notify "green" "docker cp $HOSTNAME:/usr/src/build/log <destination>" true
fi

build_make_opts
prepare_repo "$GLUON_SITEDIR" $SITE_URL
prepare_repo "$GLUON_GLUONDIR" $GLUON_URL
git_checkout "$GLUON_GLUONDIR" $GLUON_VERSION
check_targets
check_domains

if [[ ! $DOMAINS_TO_BUILD == "" ]]
then
	arr=($DOMAINS_TO_BUILD)
	git_checkout "$GLUON_SITEDIR" "${arr[0]}"
	if [[ $SKIP_GLUON_PREBUILD_ACTIONS == 0 ]]
	then
		gluon_prepare_buildprocess
	fi
	build_selected_domains_and_selected_targets
	notify "green" "Build $GLUON_VERSION+$VERSION abgeschlossen." true
	if running_in_docker 
	then 
		force_dir_clean
		notify "green" "docker cp $HOSTNAME:$BUILD_OUTPUT_DIR <destination>" true
	fi
fi

