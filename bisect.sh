#!/bin/bash

set -x
# Fail fast and be aware of exit codes
set -eo pipefail

readonly ERR_INVALID_USAGE=2
current_datetime=$(date +"%Y_%m_%d_%I_%M_%p")
# XML files are merged into this file
combined_xml_file_name=""
# Artifacts are output files generated by Pharo test
should_clean_artifacts=true
# Old files are output files generated by this script
should_clean_files=true
stage_name=""
version="0.1"
pharo_image_directory=""
pharo_image_name=""
pharo_image_file=""
pharo_vm_file=""

show_version() {
	printf "%s\n" "$version"
	exit 0
}

show_usage() {
	cat <<-EOF
		Usage: $(basename $0) -i <image-path> [-vm <virtual-machine>]

		Commands:
			-h|--help       Show usage
			-i|--image      Run image
			-p|--vmpath	Virtual Machine
			-v|--version	Show version
	EOF
}

usage() {
	show_usage
	exit $ERR_INVALID_USAGE
}
    
die() {
	local message="$1"
	local -i exit_code="${2:-1}"

	printf "%sError $exit_code: $message%s\n" "${RED}" "${NORMAL}" >&2
	show_usage
	exit $exit_code
}

# Returns 0 if command was found in the current system, 1 otherwise
cmd_exists () {
	type "$1" &> /dev/null || [ -f "$1" ];
	return $?
}

set_stage() {
	os="$(uname)"

	case "$os" in
		Linux)
			stage_name=""
			;;
		Darwin)
			stage_name="Tests-osx-64"
			;;
		MINGW*)
			stage_name=""
			;;
		(*)
			die "OS not found\n"
			;;
	esac
}

# Run tests for the host platform
run_tests(){
    "$pharo_vm_file" --headless "$pharo_image_file" --no-default-preferences test --junit-xml-output --stage-name="$stage_name" '.*'
}

# Check if external programs are installed, or stop execution.
check_requirements() {
	local list_dir

	# Check required programs are available
    cmd_exists jrm || { die "jrm is missing. Install with: npm install -g junit-report-merger\n"; }
    cmd_exists xpath || { die "xpath is missing\n"; }

	# Check the Pharo image exists
	[[ -f "$pharo_image_file" ]] || { die "Image file does not exist\n"; }

	# Check the Pharo vm script exists

	if [ ! -f "$pharo_vm_file" ]; then
		printf "No VM script was found in the specified image directory\n"
		printf "If the provided image is in a Pharo Launcher directory, please specify the VM path\n\n"
		printf "These are the VM's executables in the Pharo Launcher directory relative to the image path, if exists\n\n"
		list_dir="$pharo_image_directory/../../vms"
		find "$list_dir" -type f -name "Pharo" -exec realpath {} \;
		exit 0
	else
		printf "Found VM at: %s\n" "$pharo_vm_file"
	fi
}

# Combine all XML files into a single XML, and delete them once finished.
combine_xml_files() {
    jrm "$combined_xml_file_name" ./*.xml
    [[ -f "$combined_xml_file_name" ]] || { die "Could not combine XML files\n"; }
}

clean_artifacts(){
	if [ $should_clean_artifacts == true ] ; then
		find . -name '*.fuel' -exec rm \{\} +
		clean_xml_files
		rm -fv serialized_stack progress.log
    fi
}

clean_xml_files() {
	find . -name '*.xml' ! -name "$combined_xml_file_name" -exec rm \{\} +
}

clean_old_runs() {
	if [ "$should_clean_files" == true ]; then
		clean_xml_files
		find . -name 'failures*txt' -exec rm \{\} +
	fi
}

# Filter and write output files
filter_failures() {
	local raw_failures_file_name="failures-raw-$pharo_image_name-$current_datetime.txt"
	local grep_failures_file_name="failures-grep-$pharo_image_name-$current_datetime.txt"

    # Filter failed tests and write output to text file
    xpath -e '/testsuites//failure/text()' "$combined_xml_file_name" > "$raw_failures_file_name"

    # Filter only the class name and test selector
    grep '>>.*test.*' "$raw_failures_file_name" > "$grep_failures_file_name"
}

bisect() {
	set_stage
	clean_old_runs
    check_requirements
	run_tests
    combine_xml_files
	clean_artifacts
    filter_failures
}

main () {
    # Parse options using getopt
    local OPTIND opt
    local long_opts="h,i:,p:,v"
    local image=""

    # Set a flag to track if the image parameter was provided
    local image_provided=0

    while getopts "$long_opts" opt; do
        case $opt in
            h|help)
                show_usage
                exit 0
                ;;
            i|image)
                image="$OPTARG"
                image_provided=1
                ;;
            p|vmpath)
                pharo_vm_file="$OPTARG"
                ;;
			v|version)
				show_version
				;;
			\?)
				die "Invalid option: -$OPTARG" >&2
				;;
			:)
				die "Option -$OPTARG requires an argument." >&2
				;;
			esac
    done

    shift $((OPTIND - 1))

    # Check if the image parameter was provided
    if [ "$image_provided" -eq 0 ]; then
        die "Error: Image parameter is mandatory"
    fi

	# Set global variables
	pharo_image_directory=$(dirname "$image")
	pharo_image_name=$(basename "$image")
	pharo_image_file="$pharo_image_directory"/"$pharo_image_name"

    # Lazy initialization of vmpath to "pharo" in the image directory if not set
    if [ -z "$pharo_vm_file" ]; then
		pharo_vm_file="$pharo_image_directory/pharo"
    fi

	# JENKINS_HOME
	combined_xml_file_name="junit-$pharo_image_name-$current_datetime.xml"

    # Process the command with the provided parameters
    bisect
}

main "$@"