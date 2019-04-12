# Extract contents from a TextGrid to a CSV file

clearinfo

# =================================================================================================================================================

# Constants for the tiers - means you can write the name of the tier instructions
# rather than just the tier number, which can be a bit confusing.
# *** CHECK THESE ARE CORRECT BEFORE RUNNING THE SCRIPT ***
utteranceTier = 1
wordTier = 2
phoneTier = 3
soundTier = 4
impTier = 5
notesTier = 6
f1Tier = 7
f2Tier = 8

# =================================================================================================================================================

# Select annotations file to process (TextGrid)
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

sep$ = ","

Read from file... 'inputFile$'
objectName$ = selected$("TextGrid")

# Select file for output
extIndex = rindex(filename$, ".")
if extIndex <> 0
    filename$ = left$(filename$, extIndex)
endif
filepath$ = directory$ + filename$ + "csv"

header$ = "sound_label"
...+ sep$ + "sound_start"
...+ sep$ + "sound_end"
...+ sep$ + "word"
...+ sep$ + "utterance"
...+ sep$ + "F1_20"
...+ sep$ + "F1_35"
...+ sep$ + "F1_50"
...+ sep$ + "F1_65"
...+ sep$ + "F1_80"
...+ sep$ + "F2_20"
...+ sep$ + "F2_35"
...+ sep$ + "F2_50"
...+ sep$ + "F2_65"
...+ sep$ + "F2_80"

# Check if file exists
deleteFile: filepath$
writeFileLine: filepath$, header$


# =================================================================================================================================================

numTiers = Get number of tiers
for tierNum from 1 to numTiers
    tierName$ = Get tier name... 'tierNum'
    appendInfoLine: "We are on tier:", tierName$
    endfor

#This loop looks through "soundtier" and prints the content of each non-empty interval
num_tokens = Get number of intervals... soundTier
num_utterances = Get number of intervals... utteranceTier
num_words = Get number of intervals... wordTier
num_f1_points = Get number of points... f1Tier
num_f2_points = Get number of points... f2Tier

for i from 1 to num_tokens
    token$ = Get label of interval... soundTier i
    start = Get start point: soundTier, i
    end = Get end point: soundTier, i
    if token$ <> ""
    appendInfoLine: string$(start) + "--" + string$(end)
    appendFile: filepath$, token$ + sep$ + string$(start) + sep$ + string$(end) + sep$
        
        for word from 1 to num_words
            word$ = Get label of interval... wordTier word
            word_start = Get start point: wordTier, word
            word_end = Get end point: wordTier, word
            if (word_start <= start) and (word_end >= end)
            appendFile: filepath$, word$ + sep$
            endif
        endfor
        for utterance from 1 to num_utterances
            utt$ = Get label of interval... utteranceTier utterance
            utt$ = replace$(utt$, ",", "", 0)
            utt_start = Get start point: utteranceTier, utterance
            utt_end = Get end point: utteranceTier, utterance
            if (utt_start <= start) and (utt_end >= end)
            appendFile: filepath$, utt$ + sep$
            endif
       endfor
        for point from 1 to num_f1_points
        pointTime = Get time of point: f1Tier, point
            if pointTime >= start and pointTime <= end
            f1$ = Get label of point... f1Tier point
            appendFile: filepath$, f1$ + sep$
            endif
        endfor
        for pointf2 from 1 to num_f2_points
        pointf2Time = Get time of point: f2Tier, pointf2
            if pointf2Time >= start and pointf2Time <= end
            f2$ = Get label of point... f2Tier pointf2
            appendFile: filepath$, f2$ + sep$
            endif
        endfor
    appendFileLine: filepath$
    else i = i+1
    endif
endfor

select TextGrid 'objectName$'
View & Edit
Remove
exitScript: "A CSV file has been created", newline$, filepath$
