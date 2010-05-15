#!/usr/bin/env python

###########################################################################################
# n900-encode.py: Encode almost any Video to an Nokia N900-compatible format (h264,aac,mp4)
# Disclaimer: This program is provided without any warranty, USE AT YOUR OWN RISK!
#
# (C) 2010 Stefan Brand <seiichiro@seiichiro0185.org>
#
# Version 0.2
###########################################################################################

import sys, os, getopt, subprocess, re, atexit
from signal import signal, SIGTERM, SIGINT
from time import sleep

version = "0.2"

###########################################################################################
# Default values, feel free to adjust
###########################################################################################

_basewidth = 800 		# Base width for widescreen Video
_basewidth43 = 640	# Base width for 4:3 Video
_maxheight = 480		# maximum height allowed
_abitrate = 112			# Audio Bitrate in kBit/s
_vbitrate = 22		 	# Video Bitrate, if set to value < 52 it is used as a CRF Value for Constant rate factor encoding
_threads = 0				# Use n Threads to encode (0 means use number of CPUs / Cores)
_mpbin = None				# mplayer binary, if set to None it is searched in your $PATH
_mcbin = None				# mencoder binary, if set to None it is searched in your $PATH
_m4bin = None 			# MP4Box binary, if set to None it is searched in your $PATH

###########################################################################################
# Main Program, no changes needed below this line
###########################################################################################

def main(argv):
	"""Main Function, cli argument processing and checking"""

	# CLI Argument Processing
	try:
		opts, args = getopt.getopt(argv, "i:o:m:v:a:t:hf", ["input=", "output=", "mpopts=", "abitrate=", "vbitrate=", "threads=", "help", "force-overwrite"])
	except getopt.GetoptError, err:
		print str(err)
		usage()

	input = None
	output = "n900encode.mp4"
	mpopts = ""
	abitrate = _abitrate
	vbitrate = _vbitrate
	threads = _threads
	overwrite = False
	for opt, arg in opts:
		if opt in ("-i", "--input"):
			input = arg
		elif opt in ("-o" "--output"):
			output = arg
		elif opt in ("-m" "--mpopts"):
			mpopts = arg
		elif opt in ("-a", "--abitrate"):
			abitrate = int(arg)
		elif opt in ("-v", "--vbitrate"):
			vbitrate = int(arg)
		elif opt in ("-t", "--threads"):
			threads = arg
		elif opt in ("-f", "--force-overwrite"):
			overwrite = True
		elif opt in ("-h", "--help"):
			usage()

	# Check for needed Programs
	global mpbin
	mpbin = None
	if not _mpbin == None and os.path.exists(_mpbin) and not os.path.isdir(_mpbin):
		mpbin = _mpbin
	else:
		mpbin = progpath("mplayer")
	if mpbin == None:
		print "Error: mplayer not found in PATH and no binary given, Aborting!"
		sys.exit(1)

	global mcbin
	mcbin = None
	if not _mcbin == None and os.path.exists(_mcbin) and not os.path.isdir(_mcbin):
		mcbin = _mcbin
	else:
		mcbin = progpath("mencoder")
	if mcbin == None:
		print "Error: mencoder not found in PATH and no binary given, Aborting!"
		sys.exit(1)

	global m4bin
	m4bin = None
	if not _m4bin == None and os.path.exists(_m4bin) and not os.path.isdir(_m4bin):
		m4bin = _m4bin
	else:
		m4bin = progpath("MP4Box")
	if m4bin == None:
		print "Error: mencoder not found in PATH and no binary given, Aborting!"
		sys.exit(1)

	# Check input and output files
	if not os.path.isfile(input):
		print "Error: input file is not a valid File or doesn't exist"
		sys.exit(2)

	if os.path.isfile(output):
		if overwrite:
			os.remove(output)
		else:
			print "Error: output file " + output + " already exists, force overwrite with -f"
			sys.exit(1)

	# Start Processing
	res = calculate(input)
	convert(input, output, res, _abitrate, vbitrate, threads, mpopts)
	sys.exit(0)


def calculate(input):
	"""Get Characteristics from input video and calculate resolution for output"""

	# Get characteristics using mplayer
	cmd=[mpbin, "-ao", "null", "-vo", "null", "-frames", "0", "-identify", input]
	mp = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
	
	try:
		s = re.compile("^ID_VIDEO_ASPECT=(.*)$", re.M)
		m = s.search(mp[0])
		orig_aspect = m.group(1)
		s = re.compile("^ID_VIDEO_WIDTH=(.*)$", re.M)
		m = s.search(mp[0])
		orig_width = m.group(1)
		s = re.compile("^ID_VIDEO_HEIGHT=(.*)$", re.M)
		m = s.search(mp[0])
		orig_height = m.group(1)
		s = re.compile("^ID_VIDEO_FPS=(.*)$", re.M)
		m = s.search(mp[0])
		fps = m.group(1)

	except:
		print "Error: unable to identify source video, exiting!"
		sys.exit(2)

	# Calculate output resolution
	if float(orig_aspect) == 0 or orig_aspect == "":
		orig_aspect = float(orig_width)/float(orig_height)
	width = _basewidth
	height = int(round(_basewidth / float(orig_aspect) / 16) * 16)
	if (height > _maxheight):
		width = _basewidth43
		height = int(round(_basewidth43 / float(orig_aspect) / 16) * 16)

	return (width, height, fps)


def convert(input, output, res, abitrate, vbitrate, threads, mpopts):
	"""Convert the Video"""

	# Needed for cleanup function
	global h264, aac

	# define some localvariables
	pid = os.getpid()
	h264 = output + ".h264"
	aac = output + ".aac"
	width = str(res[0])
	height = str(res[1])
	fps = str(res[2])

	if (vbitrate < 52):
		vbr = "crf=" + str(vbitrate)
	else:
		vbr = "bitrate=" + str(vbitrate)
	
	# Define mencoder command for video encoding
	mencvideo = [ mcbin,
			"-ovc", "x264",
			"-x264encopts", vbr + ":bframes=0:trellis=0:nocabac:no8x8dct:level_idc=30:frameref=4:me=umh:weightp=0:vbv_bufsize=2000:vbv_maxrate=1800:threads=" + str(threads),
			"-sws", "9",
			"-vf", "scale=" + width + ":" + height + ",dsize=" + width + ":" + height + ",fixpts=fps=" + fps + ",ass,fixpts,harddup",
			"-of", "rawvideo", 
			"-o", h264,
			"-nosound",
			"-noskip",
			"-ass",
			input ]
	if (mpopts != ""):
		for mpopt in mpopts.split(" "):
			mencvideo.append(mpopt)

	# Define mencoder command for audio encoding
	mencaudio = [ mcbin,
			"-oac", "faac",
			"-faacopts", "br=" + str(abitrate) + ":mpeg=4:object=2",
			"-ovc", "copy",
			"-mc", "0",
			"-vf", "softskip",
			"-of", "rawaudio",
			"-o", aac,
			"-noskip",
			input ]
	if (mpopts != ""):
		for mpopt in mpopts.split(" "):
			mencaudio.append(mpopt)


	# Define MB4Box Muxing Command
	mp4mux = [ m4bin,
			"-fps", fps,
			"-new", "-add", h264,
			"-add", aac,
			output ]
	
	# Encode Video
	print "### Starting Video Encode ###"
	try:
		subprocess.check_call(mencvideo)
		print "### Video Encoding Finished. ###"
	except subprocess.CalledProcessError:
		print "Error: Video Encoding Failed!"
		sys.exit(3)
	
	print "### Starting Audio Encode ###"
	try:
		subprocess.check_call(mencaudio)
		print "### Audio Encode Finished. ###"
	except subprocess.CalledProcessError:
		print "Error: Audio Encoding Failed!"
		sys.exit(3)

	# Mux Video and Audio to MP4
	print "### Starting MP4 Muxing ###"
	try:
		subprocess.check_call(mp4mux)
		print "### MP4 Muxing Finished. Video is now ready! ###"
	except subprocess.CalledProcessError:
		print "Error: Encoding thread failed!"
		sys.exit(4)


def progpath(program):
	"""Get Full path for given Program"""

	for path in os.environ.get('PATH', '').split(':'):
		if os.path.exists(os.path.join(path, program)) and not os.path.isdir(os.path.join(path, program)):
			return os.path.join(path, program)
	return None

def cleanup():
	"""Clean up when killed"""

	# Cleanup
	try:
		os.remove(h264)
		os.remove(aac)
	finally:
		sys.exit(0)


def usage():
	"""Print avaiable commandline arguments"""

	print "This is n900-encode.py Version" + version + "(C) 2010 Stefan Brand <seiichiro0185 AT tol DOT ch>"
	print "Usage:"
	print "  n900-encode.py --input <file> [opts]\n"
	print "Options:"
	print "  --input <file>    [-i]: Video to Convert"
	print "  --output <file>   [-o]: Name of the converted Video"
	print "  --mpopts \"<opts>\" [-m]: Additional options for mplayer (eg -sid 1 or -aid 1) Must be enclosed in \"\""
	print "  --abitrate <br>   [-a]: Audio Bitrate in KBit/s"
	print "  --vbitrate <br>   [-v]: Video Bitrate in kBit/s, values < 0 activate h264 CRF-Encoding, given value is used as CRF Factor"
	print "  --threads <num>   [-t]: Use <num> Threads to encode, giving 0 will autodetect number of CPUs"
	print "  --force-overwrite [-f]: Overwrite output-file if existing"
	print "  --help            [-h]: Print this Help"
	sys.exit(0)


# Start the Main Function
if __name__ == "__main__":
	# Catch kill and clean up
	atexit.register(cleanup)

	signal(SIGTERM, lambda signum, stack_frame: exit(1))
	signal(SIGINT, lambda signum, stack_frame: exit(1))

	# Check min params and start if sufficient
	if len(sys.argv) > 1:
		main(sys.argv[1:])
	else:
		print "Error: You have to give an input file at least!"
		usage()
