# This script takes a TextGrid and a soundfile of the same name (make sure they are called the same thing, and in the same directory!).
# You need to have already segmented your vowel tokens on an interval tier.
# The script goes through the intervals on the vowel tier and for each vowel token, measures the F1 and F2 at as many time points as you wish,
# and stores the measurements in point tiers at the bottom.
# I have a separate script for extracting these measurements to csv, because the idea is that you measure your diphthongs, then visually inspect
# and check that the measurements look correct (if the measurements are wildly off, you can fiddle with the formant extraction parameters in
# this script and then try running it again to see if you get a better result), and extract to csv only once you've checked the output.
# I recommend opening this script in Sublime Text rather than Praat.

# =================== Set your parameters ==================
# Define the measurement points. E.g. 0.2 = 20% of the duration of the vowel segment.
point20 = 0.2
point35 = 0.35
point50 = 0.5
point65 = 0.65
point80 = 0.8

# Audio file extension - change for .wav files
ext$ = "wav"

# Formant extraction parameters as parsed by Praat's `Formant: to burg'
timeStep = 0.0025
numberofFormants = 5
maxFormantFrequency = 5000
windowLength = 0.025
preEmphasisFrom = 50

# Constants for the interval tiers you've got in your TextGrid - means you can write the name of the tier instructions
# rather than just the tier number, which can be a bit confusing	
utteranceTier = 1
phoneTier = 3
wordTier = 2
soundTier = 4

# =================== Processing to add formant tiers ==================

# Select annotations file to process. NB your sound file needs to have the same name and end with `.wav' and be in the same directory
inputFile$ = chooseReadFile$: "Select the annotation file"

filenameIndex = rindex(inputFile$, "/")
if filenameIndex == 0
	filenameIndex = rindex(inputFile$, "\")
endif
if filenameIndex <> 0
	filename$ = right$(inputFile$, length(inputFile$) - filenameIndex)
	directory$ = left$(inputFile$, filenameIndex)
else
	exitScript: "Unable to parse file name for directory and file"
endif
appendInfoLine: "Filename: ", filename$
appendInfoLine: "Directory: ", directory$


Read from file... 'inputFile$'
objectName$ = selected$("TextGrid")
# Reads in the .wav file that accompanies the textgrid
Read from file... 'directory$''objectName$'.'ext$'
# This bit is key! It uses the parameters you specified earlier
To Formant (burg)... timeStep numberofFormants maxFormantFrequency windowLength preEmphasisFrom

select TextGrid 'objectName$'

#Count the number of interval and point tiers in the textgrid
# Set iteration variables to zero
numIntervalTiers = 0
numPointTiers = 0
numTiers = Get number of tiers
for tierNum from 1 to numTiers
	isInterval = Is interval tier... 'tierNum'
	# if it's an interval tier, add to the interval tier counter
	if isInterval
		numIntervalTiers = numIntervalTiers + 1
		# otherwise, add to the point tier counter
	else
		numPointTiers = numPointTiers + 1
	endif
endfor

# Remove point tiers (and add your own from scratch)
# Iterates through the tiers, starting at the bottom tier and then minusing one,
# i.e. moving up one tier at the end of each iteration
tierNum = numTiers
while (tierNum > 0)
	isInterval = Is interval tier... 'tierNum'
	# if it's not an interval tier, get rid of it
	if not isInterval
		Remove tier... 'tierNum'
	endif
	tierNum = tierNum - 1
endwhile

# Add new point tiers. These are empty for now, but by the end, they will have your measurements in them
numTiers = Get number of tiers
f1Tier = numTiers + 1
f2Tier = numTiers + 2
notesTier = numTiers + 3
Insert point tier... 'f1Tier' "F1"
Insert point tier... 'f2Tier' "F2"
Insert point tier... 'notesTier' "Notes"

# Get interval data. This procedure gets used later and is iterated through the intervals of the interval tiers
# The procedure is called getInterval and you must supply
# the tier and the interval number
procedure getInterval: .intervalTier, .intervalNum
	appendInfo: "Tier: ", .intervalTier, ", Sound:", .intervalNum, " -- "
	# the text in the interval is stored in string variable label$
	.label$ = Get label of interval... .intervalTier .intervalNum
	# the start and end times of the interval are stored in numeric variables
	.start = Get start point: .intervalTier, .intervalNum
	.end = Get end point: .intervalTier, .intervalNum
endproc

# Find an interval which encapsulates a given start and end time
#- i.e. given start and end fall *inside* this interval
# The procedure is called "findInterval" and it requires you to supply interval tier and start and end
# times
procedure findInterval: .intervalTier, .startTime, .endTime
	.numIntervals = Get number of intervals... .intervalTier
	.intervalNum = 1
	.found = 0
	while (.found = 0) and (.intervalNum <= .numIntervals)
		.label$ = Get label of interval... .intervalTier .intervalNum
		.start = Get start point: .intervalTier, .intervalNum
		.end = Get end point: .intervalTier, .intervalNum
		# I think this line makes sure that: the interval is not empty;
		#and the time is between the start and end points of the interval
		.found = .label$ <> "" and .startTime >= .start and .endTime <= .end
		# so then if the interval actually is empty, skip to the next interval
		if .found = 0
			.intervalNum = .intervalNum + 1
		endif
	endwhile
endproc

# This is the procedure for adding a point tier. you have to supply the time,
# the F1 and F2 values, and the notes - i.e. you supply what should be written on each tier
procedure addPoint: .time, .f1, .f2, .notes$
	roundedF1 = round(.f1 * 100) / 100
	roundedF2 = round(.f2 * 100) / 100
	Insert point... f1Tier .time 'roundedF1'
	Insert point... f2Tier .time 'roundedF2'
	Insert point... notesTier .time '.notes$'
endproc

# Find formants
# Find the number of intervals on the sound tier (i.e. tier 4 at the moment)
numSounds = Get number of intervals... soundTier
for sound from 1 to 'numSounds'
# Find sounds
# The @ calls the procedure "get interval".
	@getInterval: soundTier, sound
	# The temporary variable label$ is stored in this iteration as soundLabel$
	soundLabel$ = getInterval.label$
	soundStart = getInterval.start
	soundEnd = getInterval.end
	if soundLabel$ <> ""
	# As long as the sound label isn't empty, go to the sound's interval on the word tier
		@findInterval: wordTier, soundStart, soundEnd
		if findInterval.found = 0
		# the script blows up if there isn't a word encapsulating the sound interval!
			exitScript: "Unable to find a word for the sound from time ", soundStart, " to ", soundEnd
		endif
		wordLabel$ = findInterval.label$
		wordStart = findInterval.start
		wordEnd = findInterval.end
	# Find utterance. Same procedure as you did for word, but now on the tier above
		@findInterval: utteranceTier, wordStart, wordEnd
		if findInterval.found = 0
			exitScript: "Unable to find an utterance for the word from time ", wordStart, " to ", wordEnd
		endif
		utteranceLabel$ = findInterval.label$
		utteranceStart = findInterval.start
		utterancfeEnd = findInterval.end
	# Find formant points for the sound (all of this is the procedure just for one sound interval still!)
		soundLength = soundEnd - soundStart
		point20Time = soundStart + point20 * soundLength
		point35Time = soundStart + point35 * soundLength
		point50Time = soundStart + point50 * soundLength
		point65Time = soundStart + point65 * soundLength
		point80Time = soundStart + point80 * soundLength
		appendInfoLine: "Sound start: ", soundStart, " - first calc: ", point20Time, " - second calc: ", point35Time, " - third calc: ", point50Time, " - fourth calc:", point65Time, " - fifth calc", point80Time
		# Analyse formants
		select Formant 'objectName$'
		f1_20 = Get value at time... 1 'point20Time' Hertz Linear
		f2_20 = Get value at time... 2 'point20Time' Hertz Linear
		f1_35 = Get value at time... 1 'point35Time' Hertz Linear
		f2_35 = Get value at time... 2 'point35Time' Hertz Linear
		f1_50 = Get value at time... 1 'point50Time' Hertz Linear
		f2_50 = Get value at time... 2 'point50Time' Hertz Linear
		f1_65 = Get value at time... 1 'point65Time' Hertz Linear
		f2_65 = Get value at time... 2 'point65Time' Hertz Linear
		f1_80 = Get value at time... 1 'point80Time' Hertz Linear
		f2_80 = Get value at time... 2 'point80Time' Hertz Linear
		# Return to TextGrid
		select TextGrid 'objectName$'
		# Now we call the procedure "addPoint"
		@addPoint: point20Time, f1_20, f2_20, ""
		# the notes tier can be empty
		@addPoint: point35Time, f1_35, f2_35, ""
		@addPoint: point50Time, f1_50, f2_50, ""
		@addPoint: point65Time, f1_65, f2_65, ""
		diff1 = round((f1_80 - f1_20) * 100) / 100
		diff2 = round((f2_80 - f2_20) * 100) / 100
		@addPoint: point80Time, f1_80, f2_80, "F1: " + string$(diff1) + newline$ + "F2: " + string$(diff2)
	# Write out the results
	endif
endfor

select TextGrid 'objectName$'
plus Sound 'objectName$'
View & Edit
# Remove
exitScript: "We're all done", newline$