#!/bin/bash

combined_xml_file_name="combined.xml"
should_clean_xml_files=true
pharo_image="Pharo.image"
stage_name="Tests-osx-64"

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
    cmd_exists jrm || { printf "jrm is missing. Install with: npm install -g junit-report-merger\n"; exit 1; }
    cmd_exists xpath || { printf "xpath is missing\n"; exit 1; }
}

combine_xml_files() {
    jrm "$combined_xml_file_name" ./*.xml
    [[ -f "$combined_xml_file_name" ]] || { printf "Could not combine XML files\n"; exit;}
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

main () {
    check_requirements
    combine_xml_files
    filter_failures
}