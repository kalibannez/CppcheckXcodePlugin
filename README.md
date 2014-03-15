CppcheckXcodePlugin
===================

Plugin for Xcode that allows to make ccpcheck incremental static analysis

## Features
- At every build time plugin automatically starts cppcheck analyzer for every changed file (for both .cpp and .h)
- Easy to modify: logic of plugin separated for three parts:
	1. Xcode plugin, that hooks and dumps source file changes
	2. Xcode run script, that configure, run python script and interpret results
	3. Python run script, that interpret results of plugin, process it, do checks, process results and send to Xcode

## Installation
- Build the project and restart Xcode