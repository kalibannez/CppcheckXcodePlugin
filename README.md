CppcheckXcodePlugin
===================

Plugin for Xcode that automatically run cppcheck static analyzer for every changed file (for both .cpp and .h) at every build time

## Features
- Easy to use: just setup it once and have static analyse at every build
- Fast: cppcheck will be run only for changed files
- Easy to modify: logic of plugin separated for three parts:
	- Xcode plugin hooks and dumps source file changes
	- Xcode run script configure, run python script and interpret it results
	- Python IncrementalCppCheck.py script interpret results of plugin, process it, do checks, process results and send to Xcode<br>
For example, if you want to run cppckeck with special options: just change commant line arguments in IncrementalCppCheck.py

## Installation
- Install cppcheck (homebrew is recommended)
- Install Xcode plugin by building the project and restart Xcode
- Copy [IncrementalCppCheck.py](IncrementalCppCheck.py) script into your project root
- In Xcode in Build Phases tab create new Run Script and enter following script:
<code>
SCRIPT_PATH="${SRCROOT}/IncrementalCppCheck.py"<br>
&nbsp;&nbsp;WORKING_DIR=$(eval echo -e `<${PROJECT_TEMP_ROOT}"/WorkingDirPath.txt"`)<br>
&nbsp;&nbsp;/usr/bin/python $SCRIPT_PATH $WORKING_DIR<br>
&nbsp;&nbsp;if [ $? -ne 0 ] ; then<br>
&nbsp;&nbsp;      exit 1<br>
&nbsp;&nbsp;fi<br>
</code>

## Uninstallation
- Remove CppcheckXcodePlugin.xcplugin from ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins folder
- Remove created for plugin run script from Xcode
- Remove IncrementalCppCheck.py script from your project folder

## License
CppcheckXcodePlugin is released under the BSD LICENSE (see the LICENSE file)

## Contact
Any suggestions or improvements than welcome. Feel free to contact me at [kalibannez@gmail.com](mailto:kalibannez@gmail.com).
