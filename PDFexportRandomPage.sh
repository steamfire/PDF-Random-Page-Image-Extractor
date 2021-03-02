#!/bin/zsh
# This script counts the number of documents containing a certain word
# 
# Tested on OSX High Sierra 10.13.6
# Dan Bowen steamfire@gmail.com
# INPUT: list of PDF paths provided as arguments
# OUTPUT: 
#
# Requires: 
# zshell (zsh)
# Imagemagick (for mogrify)
# poppler (for pdftocairo)
# coreutils (for realpath)
# mdls (for PDF pagecount, comes with OSX.  Uses the spotlight index so that it doesn't have to process the PDFs when this command is used.  Lightweight on CPU!)


#TO DO
#  Include input arg for pictures output directory


USAGE="

Usage: command numberOfPDFs numberOfPagesPerPDF InputPathToTopLevelDirectory OutputPathForImages

This requires three arguments.  a numberOfPDFs to pull randomly from the directories hierarchy, numberOfPagesPerPDF to pull randomly FROM EACH PDFs, and finally a path to the top level directory containing PDF and/or subfolders of PDFs.

Not yet sure if it works with spaces or special chars.
This will crawl through all subdirectories to look for PDFs.

"

if [ $# -ne 4 ] ; then
    directoryToOutput="./"
else
    directoryToOutput=$4
fi

if [ $# -lt 3 ] ; then
    echo $USAGE
    exit 1;
fi

OUTPUTIMAGEEXTENSION="png"
OUTPUTIMAGEWIDTH=1440

totalFiles=0
currentFileStatus=0
PAGECOUNT=0
numberOfPDFs=$1
numberOfPagesPerPDF=$2
#textToSearchFor=$1
directoryToCrawl=$3

dateNow=`/bin/date +"%Y-%m-%d"`

totalImagesToCreate=$numberOfPDFs*numberOfPagesPerPDF

echo -e "FIGURE OUT HOW TO PASS ESCAPED FILE NAMES AS THE OUTPUT DIRECTORY PATH! NOT FINISHED"

echo -e "Directory: $directoryToCrawl \nNumber of PDFs to pull: $numberOfPDFs\nNumber of pages per PDF: $numberOfPagesPerPDF"
#Find files in the provided directory tree

SELECTEDPDFS=`find "$directoryToCrawl" -iname '*.pdf' -print | shuf -n "$numberOfPDFs"`

echo "$SELECTEDPDFS" |  while read thisLine

#find "$directoryToCrawl" -iname '*.pdf' -print | sort | while read thisLine


do
    targetFilePath=$thisLine
    targetFileName=$targetFilePath:t
    targetFileAbsolutePath=`realpath "$targetFilePath"`
    echo -n " $targetFileName:  "
    ##Get the text printed out of the info of the PDF file
    ##currentFileInfo=`/usr/local/bin/pdfinfo "$targetFilePath"`
    #Get page count of the current file
    PAGECOUNT=`/usr/bin/mdls -raw -name kMDItemNumberOfPages "$targetFilePath"`
    echo -n "Total Pages in PDF: $PAGECOUNT"
    #if mdls exited with an error code (greater than 1)
     if [ ${?} -gt 0 ] ; then
         echo -e "*****  MDLS Error ${?} from $targetFilePath *****\n\n"
     fi
    #****LOOP to process the number of pages in each PDF****
    echo -n "    Outputting: "
    for ((i = 0; i < $numberOfPagesPerPDF; i++))
     do 
    
        #Generate a random page number
        RANDOMPAGENUMBER=`jot -r 1 1 $PAGECOUNT`
        echo -n "$RANDOMPAGENUMBER, "
        OUTPUTIMAGEFILENAME="$targetFileName--page$RANDOMPAGENUMBER.$OUTPUTIMAGEEXTENSION"
        OUTPUTIMAGEPATH="$directoryToOutput$OUTPUTIMAGEFILENAME"
        echo -e " Output Path: $OUTPUTIMAGEPATH"
        OUTPUTHEADERTEXT="$targetFileName"
        OUTPUTHEADER2TEXT="Page $RANDOMPAGENUMBER"
        OUTPUTFOOTERTEXT="Extracted on $dateNow"
        #Generate a jpg of the selected page without the page number appended
        #pdftocairo -jpeg -jpegopt optimize=y -f $RANDOMPAGENUMBER -l $RANDOMPAGENUMBER -singlefile "$targetFilePath
        
        #Generate a jpg of the selected page and output to STDOUT, processing with mogrify to add formatted text:
        pdftocairo -png -f $RANDOMPAGENUMBER -l $RANDOMPAGENUMBER -scale-to-x $OUTPUTIMAGEWIDTH -scale-to-y -1 -singlefile "$targetFilePath" - \
        | mogrify -font helvetica -fill orange -pointsize 36 -gravity north -write "$OUTPUTIMAGEFILENAME" -draw "text 0,10 '$OUTPUTHEADERTEXT'" \
        -draw "text 0,50 '$OUTPUTHEADER2TEXT'"\
         -pointsize 24 -gravity south -draw "text 0,10 '$OUTPUTFOOTERTEXT'" -quality 70 - 
    
    
    echo -e "$dateNow, Page:, $RANDOMPAGENUMBER, $targetFileAbsolutePath" >> pdfImageExtractionLog.txt
    
    done
    echo -e
    
    (( totalFiles++ ))
done

#FYI the following command won't work in the BASH shell, because bash executes a WHILE loop in a subshell, and can't modify global variables from within it.  this took forever to figure out.
# the \a is a terminal bell beep.
echo -e "\nTotal Files Processed: $totalFiles"
