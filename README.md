CppcheckXcodePlugin
===================

Plugin for Xcode that allows to make ccpcheck incremental static analysis

## Features
- At every build time plugin automatically starts cppcheck analyzer for every changed file (for both .cpp and .h)
- Easy to modify: logic of plugin separated for three parts:
	- Xcode plugin, that hooks and dumps source file changes
	- Xcode run script, that configure, run python script and interpret results
	- Python run script, that interpret results of plugin, process it, do checks, process results and send to Xcode

## Installation
- Install Xcode plugin by building the project and restart Xcode
- Copy IncrementalCppCheck.py script into your project root
- In Xcode in Build Phases tab create new Run Script and enter following script:
<code>
SCRIPT_PATH="${SRCROOT}/IncrementalCppCheck.py"<br>
&nbsp;&nbsp;WORKING_DIR=$(eval echo -e `<${PROJECT_TEMP_ROOT}"/WorkingDirPath.txt"`)<br>
&nbsp;&nbsp;/usr/bin/python $SCRIPT_PATH $WORKING_DIR<br>
&nbsp;&nbsp;if [ $? -ne 0 ] ; then<br>
&nbsp;&nbsp;      exit 1<br>
&nbsp;&nbsp;fi<br>
</code>
