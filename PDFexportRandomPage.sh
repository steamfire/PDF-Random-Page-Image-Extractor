#!/bin/zsh
# This script selects random PDF files from a folder and all subfolders, and 
#   extracts image(s) of random pages from the selected PDFs. Appends all image file paths
#   to a text CSV log file.
# 
# Tested on OSX High Sierra 10.13.6
# Dan Bowen steamfire@gmail.com
# MIT License
#
# INPUT: list of PDF paths provided as arguments
# OUTPUT: image files, CSV text log of all runs of the command.  (previous runs will be left
#   in the file.)
#
# Requires: 
# zshell (zsh)
# Imagemagick (for mogrify)
# poppler (for pdftocairo)
# coreutils (for realpath)
# mdls (for PDF pagecount, comes with OSX.  Uses the spotlight index so that it doesn't have to process the PDFs when this command is used.  Lightweight on CPU!)


#TO DO
#  Include input arg for pictures output directory
# Output all PDF image filenames to Stdout
#"FIGURE OUT HOW TO PASS ESCAPED FILE NAMES AS THE OUTPUT DIRECTORY PATH! NOT FINISHED"


##### NEXT LINE IS FOR DEBUGGING ONLY, DO NOT LEAVE ENABLED ####
set -- --pdfs 1 --pages 1 --verbose /Users/admin/Dropbox/BalloonConsulting/PDF\ Workflow\ Redevelopment\ Scratch\ Folder\ 2020/Test\ Spell\ checking/2020\ PDF\ samples/

USAGE="
Program to find random PDF files and export random pages from the PDFs as image files.

Usage: PDFExportRandomPage.sh --pdfs # --pages #  [--img png|jpg|tiff|pdf ] [--logdir path] [--verbose] --dryrun InputDirectory  [OutputDirectory]

This requires three arguments.  --pdfs, --pages, and InputDirectory

    --pdfs is the quantity of PDFs that you would like it to pull randomly from the input 
    directory and subfolders.
    --pages is the quantity of pages to pull from each PDF
    InputDirectory is the path to the directory containing PDFs.
    --img is the format to make the output images.  Common image file suffixes  work here.
    --logdir is the directory to output the processing log file
    --verbose prints detailed information to STDOUT console as it progresses through 
    the process.
    --dryrun runs the parts that pick the files and pages, and shows the image filename that would have been created.
    OutputDirectory is the destination directory to place the image files.
    
    Will default to output images and log file to current directory.

Not yet sure if it works with spaces or special chars.
This will crawl through all subdirectories to look for PDFs.

"

# Use `$echoLog "whatever message here"` everywhere you print verbose logging messages to console
# By default, it is disabled and will be enabled with the `-v` or `--verbose` flags
declare echoLog='silentEcho'

#No-op function that gets executed when verbose mode is off.
function silentEcho() {
    :
}


#Load the utility that has zparseopts in it, to parse the input arguments to the script
zmodload zsh/zutil
zparseopts -D -E -A  opts -pdfs: -pages: -img: -verbose -dryrun -imgdir: -logdir:


#if no path was provided then print the usage information
if [ $# -lt 1 ] ; then
    echo $USAGE
    exit 1;
fi

#Check for the verbose flag in the list of arguments
if [[ -n ${opts[(ie)--verbose]} ]]; then
  echoLog='echo'
fi

#Check for the dryrun flag in the list of arguments
if [[ -n ${opts[(ie)--dryrun]} ]]; then
    dryrun=true
    $echoLog -e "DRY RUN"
else
    dryrun=false
fi

#Check for the image format option in the list of arguments
if [[ -n ${opts[(ie)--img]} ]]; then
    OUTPUTIMAGEEXTENSION=$opts[--img]
    $echoLog -e "Format: $OUTPUTIMAGEEXTENSION"
else
    OUTPUTIMAGEEXTENSION="png"
fi

#Set the output directory to current directory if none provided
if [ $# -ne 2 ] ; then
    directoryToOutput="./"
else
    directoryToOutput=$2
fi


$echoLog -e "VERBOSE MODE ON
PDF Export Random Page script
Dan Bowen 2021
MIT License"

OUTPUTIMAGEWIDTH=1440

totalFiles=0
currentFileStatus=0
PAGECOUNT=0
numberOfPDFs=$opts[--pdfs]
numberOfPagesPerPDF=$opts[--pages]
directoryToCrawl=$1
directoryForLogFile=$opts[--logdir]

dateNow=`/bin/date +"%Y-%m-%d"`

totalImagesToCreate=$numberOfPDFs*numberOfPagesPerPDF

#Check if the input directory exists, exit if not
if [ -d "$directoryToCrawl" ]; then
    $echoLog -e "Input Directory: $directoryToCrawl\n"
else 
    echo "Directory Not Found: $directoryToCrawl."
    exit
fi

$echoLog -e "
Input Directory: $directoryToCrawl\n
Will pull: $numberOfPagesPerPDF pages each from: $numberOfPDFs PDF files"
$echoLog -e ""
#Find files in the provided directory tree


#Count files found
allPDFsFound=`find "$directoryToCrawl" -iname '*.pdf' -print`
qtyPDFsFound=`printf '%s' "$allPDFsFound" | wc -l`

#Exit if no files were found
if [ "$qtyPDFsFound" -lt 1 ] ; then
    $echoLog -e "\nERROR: No PDFs found."
    exit
fi

$echoLog -n "Total PDFs found: "
$echoLog -e `echo "$allPDFsFound" | wc -l`
$echoLog -e "All pdfs list: $allPDFsFound"

SELECTEDPDFS=`find "$directoryToCrawl" -iname '*.pdf' -print | shuf -n "$numberOfPDFs"`

$echoLog "$SELECTEDPDFS" |  while read thisLine

#find "$directoryToCrawl" -iname '*.pdf' -print | sort | while read thisLine


do
    targetFilePath=$thisLine
    targetFileName=$targetFilePath:t
    targetFileAbsolutePath=`realpath "$targetFilePath"`
    $echoLog -n " $targetFileName:  "
    ##Get the text printed out of the info of the PDF file
    ##currentFileInfo=`/usr/local/bin/pdfinfo "$targetFilePath"`
    #Get page count of the current file
    PAGECOUNT=`/usr/bin/mdls -raw -name kMDItemNumberOfPages "$targetFilePath"`
    $echoLog -n "Total Pages in PDF: $PAGECOUNT"
    #if mdls exited with an error code (greater than 1)
     if [ ${?} -gt 0 ] ; then
         $echoLog -e "*****  MDLS Error ${?} from $targetFilePath *****\n\n"
     fi
    #****LOOP to process the number of pages in each PDF****
    $echoLog -n "    Pulling page #"
    for ((i = 0; i < $numberOfPagesPerPDF; i++))
        do 
            #Generate a random page number
            RANDOMPAGENUMBER=`jot -r 1 1 $PAGECOUNT`
            $echoLog -n "$RANDOMPAGENUMBER, "
            OUTPUTIMAGEFILENAME="$targetFileName--page$RANDOMPAGENUMBER.$OUTPUTIMAGEEXTENSION"
            OUTPUTIMAGEPATH="$directoryToOutput$OUTPUTIMAGEFILENAME"
            $echoLog -e " Output Path: $OUTPUTIMAGEPATH"
            OUTPUTHEADERTEXT="$targetFileName"
            OUTPUTHEADER2TEXT="Page $RANDOMPAGENUMBER"
            OUTPUTFOOTERTEXT="Extracted on $dateNow"
            #check for dry run, if so, don't do the actual work
            if [ "$dryRun" = false ] ; then
                #Generate a jpg of the selected page without the page number appended
                #pdftocairo -jpeg -jpegopt optimize=y -f $RANDOMPAGENUMBER -l $RANDOMPAGENUMBER -singlefile "$targetFilePath
        
                #Generate a jpg of the selected page and output to STDOUT, processing with mogrify to add formatted text:
                pdftocairo -png -f $RANDOMPAGENUMBER -l $RANDOMPAGENUMBER -scale-to-x $OUTPUTIMAGEWIDTH -scale-to-y -1 -singlefile "$targetFilePath" - \
                | mogrify -font helvetica -fill orange -pointsize 36 -gravity north -write "$OUTPUTIMAGEFILENAME" -draw "text 0,10 '$OUTPUTHEADERTEXT'" \
                -draw "text 0,50 '$OUTPUTHEADER2TEXT'"\
                 -pointsize 24 -gravity south -draw "text 0,10 '$OUTPUTFOOTERTEXT'" -quality 70 - 
    
                #Save the date, page number, and the path to the PDF that the page was extracted from.
                $echoLog -e "$dateNow, Page:, $RANDOMPAGENUMBER, $targetFileAbsolutePath" >> pdfImageExtractionLog.txt
            fi
        done
    $echoLog -e
    (( totalFiles++ ))
done

#FYI the following command won't work in the BASH shell, because bash executes a WHILE loop in a subshell, and can't modify global variables from within it.  this took forever to figure out.
# the \a is a terminal bell beep.
if [ "$dryRun" = false ] ; then
    $echoLog -e "\nTotal Files Processed: $totalFiles"
else
    $echoLog -e "\nDry Run, Total Files that WOULD HAVE BEEN Processed: $totalFiles"
fi
