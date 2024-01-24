#!/bin/bash

# set -x
# Fail fast and be aware of exit codes
set -eo pipefail

readonly ERR_INVALID_USAGE=2

combined_xml_file_name="combined.xml"
should_clean_xml_files=true
pharo_image="Pharo.image"
stage_name="Tests-osx-64"

show_usage() {
	cat <<-EOF
		Usage: $(basename $0) COMMAND

		Commands:
			-h|--help       Show usage
			-i|--image      Run image
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
	exit $exit_code
}

# Returns 0 if command was found in the current system, 1 otherwise
cmd_exists () {
	type "$1" &> /dev/null || [ -f "$1" ];
	return $?
}

# Run tests for the host platform
run_tests(){
    ./pharo "$pharo_image" test --junit-xml-output --stage-name="$stage_name" '.*'
}

# Check if external programs are installed, or stop execution
check_requirements() {
    cmd_exists jrm || { die "jrm is missing. Install with: npm install -g junit-report-merger\n"; }
    cmd_exists xpath || { die "xpath is missing\n"; }
}

combine_xml_files() {
    jrm "$combined_xml_file_name" ./*.xml
    [[ -f "$combined_xml_file_name" ]] || { die "Could not combine XML files\n"; }
    if [ $should_clean_xml_files == true ] ; then
        find . -name '*.xml' ! -name "$combined_xml_file_name" -exec rm \{\} +
    fi
}

filter_failures() {
    failures_file_name="failures.txt"
    # Filter failed tests and write output to text file
    xpath -e '/testsuites//failure/text()' "$combined_xml_file_name" > "$failures_file_name"
    # Filter only the class name and test selector
    grep '>>.*test.*' "$failures_file_name"
}

bisect() {
    check_requirements
    combine_xml_files
    filter_failures
}

main () {
		[[ $# -gt 0 ]] || usage

		local command="${1:-}"
		case "$command" in
			("-h" | "--help")
				shift
				show_usage
				;;
			("-i" | "--image")
				shift
				bisect "${@:2}"
				;;
			(*)
				shift
				show_usage
				;;
		esac
}

main "$@"