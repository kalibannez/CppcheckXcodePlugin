import subprocess as sp
import sys
import os
from xml.dom import minidom
from sets import Set
import multiprocessing

def getChangedFilesFilePath() :
	try:
		changedFilesDir = sys.argv[1]
	except:
		print 'Usage: \nIncrementalCppCheck.py path_to_xcode_project_temp\n\n'
		sys.exit(1)

	changedFilesFile = changedFilesDir + '/ChangedFiles.plist'
	if not os.path.exists(changedFilesFile):
		sys.exit(0)

	return changedFilesFile

def parseChangedFiles(changedFilesFile):
	changedFiles = []

	xmldoc = minidom.parse(changedFilesFile)
	arrayTag = xmldoc.getElementsByTagName('array')
	for baseNode in arrayTag:
		for changedFileNode in baseNode.childNodes:
			if changedFileNode.nodeType == changedFileNode.ELEMENT_NODE:
				changedFiles.append(changedFileNode.childNodes[0].data)

	return changedFiles

def checkChangedFiles(changedFiles):

	filesForCheck = Set()
	for changedFile in changedFiles:
		filesForCheck.add(changedFile)
		if changedFile.endswith('.cpp'):
			headerForCpp = changedFile[:-4]+'.h'
			if os.path.exists(headerForCpp ):
				filesForCheck.add(headerForCpp)
		if changedFile.endswith('.h') :
			cppForHeader = changedFile[:-2]+'.cpp'
			if os.path.exists(cppForHeader ):
				filesForCheck.add(cppForHeader)
		if changedFile.find('/') != -1:
			filesForCheck.add('-I'+changedFile[:changedFile.rfind('/')])

	params = list()
	params.append('cppcheck')

	for fileForCheck in filesForCheck:
		params.append(fileForCheck)

	params.append('-j '+str(multiprocessing.cpu_count()))
	params.append('--enable=warning,performance,portability')
	params.append('-q')
	params.append('--template=gcc')
	params.append('--platform=unix32')
	child = sp.Popen(params, stdout=sp.PIPE, stderr=sp.PIPE)
	child.wait()
	cppcheckOutput = child.communicate()[1]

	return cppcheckOutput

def replaceWarningsForErrors(cppcheckOutput) :
	return cppcheckOutput.replace(': warning:', ': errors:')

changedFilesFilePath = getChangedFilesFilePath()
changedFiles = parseChangedFiles(changedFilesFilePath)
cppcheckOutput = checkChangedFiles(changedFiles)
errorsList = replaceWarningsForErrors(cppcheckOutput)
print errorsList

os.remove(changedFilesFilePath)

if len(errorsList):
	sys.exit(1)
