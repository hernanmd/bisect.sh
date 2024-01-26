## Introduction

The script runs the tests in the specified images (with default startup preferences), combines the output into a single XML files, filter test failures, and write two summary text files:

- The tests which failed in "raw" format, meaning as reported by the SUnit reporter.
- The tests which failed in "Class>>selector" format, with one line per failure.

These output files are timestamped so they can be diffed to see when a failure was introduced.

## Sample output

This is a sample output for the "raw" format:
```bash
...
TestFailure
Given Collections do not match!
	additions : #('NewTools-SpTextPresenterDecorators')
	missing: #()

SystemDependenciesTest(TestAsserter)>>assert:description:resumable:
SystemDependenciesTest(TestAsserter)>>assert:description:
SystemDependenciesTest(TestAsserter)>>assertCollection:hasSameElements:
SystemDependenciesTest>>testExternalIDEDependencies
SystemDependenciesTest(TestCase)>>performTest
		

TestFailure
Given Collections do not match!
	additions : #('NewTools-Morphic')
	missing: #()

SystemDependenciesTest(TestAsserter)>>assert:description:resumable:
SystemDependenciesTest(TestAsserter)>>assert:description:
SystemDependenciesTest(TestAsserter)>>assertCollection:hasSameElements:
SystemDependenciesTest>>testExternalSpec2Dependencies
SystemDependenciesTest(TestCase)>>performTest
...		

```

This is a sample output for the "Class>>selector" format:
```bash
				formatClass: class class ] in RBFormatterTest>>testCoreSystem
RBFormatterTest>>testCoreSystem
ProperMethodCategorizationTest>>testNoUncategorizedMethods
ReleaseTest>>testPharoVersionFileExists
ReleaseTest>>testThatThereAreNoSelectorsRemainingThatAreSentButNotImplemented
SpMorphicBoxLayoutTest>>testBeHomogeneous
SpMorphicBoxLayoutTest>>testBeHomogeneousWorksWhenContractingWindow
SpMorphicBoxLayoutTest>>testBeHomogeneousWorksWhenExpandingWindow
SystemDependenciesTest>>testExternalBasicToolsDependencies
SystemDependenciesTest>>testExternalIDEDependencies
SystemDependenciesTest>>testExternalSpec2Dependencies
SystemDependenciesTest>>testExternalUIDependencies

```

## Usage

The easiest way to execute it is to specify the image file and it will use the VM in the same directory as the image:

```bash
./bisect.sh -i Pharo.image
```

You can also execute the script specifying the full path to image and VM (e.g. for PharoLauncher)

```bash
/bisect.sh -i /Users/mvs/Documents/Pharo/images/Pharo12-SNAPSHOT.build.1243.sha.e4b8f88.arch.64bit/Pharo12-SNAPSHOT.build.1243.sha.e4b8f88.arch.64bit.image -p /Users/mvs/Documents/Pharo/vms/120-x64/Pharo.app/Contents/MacOS/Pharo
```
Prior to each execution, artifact files from previous execution are removed from the directory where the script is ran.

## Known issues

Sometimes the XML output written while executing tests is "malformed", which causes the xpath script to filter the failure nodes to fail. However, I couldn't find so far the cause of this behavior.

This is a sample output during a XPath parse failure:

```bash
not well-formed (invalid token) at line 19658, column 130, byte 2605549:
    <testcase classname="FileSystem.Core.Tests.DeleteVisitorTest" name="testBeta" time="0.0"/>
    <testcase classname="FileSystem.Core.Tests.DeleteVisitorTest" name="testSymbolicLink" time="0.841">
      <failure type="TestFailure" message="Got File @ /tmp/testSymbolLinkTargetPath105714316634777590822214543053449082639dir/auï¿½( instead of File @ /tmp/testSymbolLinkTargetPath105714316634777590822214543053449082639dir/a.">
=================================================================================================================================^
TestFailure
Got File @ /tmp/testSymbolLinkTargetPath105714316634777590822214543053449082639dir/auï¿½( instead of File @ /tmp/testSymbolLinkTargetPath105714316634777590822214543053449082639dir/a.
 at /System/Library/Perl/Extras/5.30/darwin-thread-multi-2level/XML/Parser.pm line 187.
 ```