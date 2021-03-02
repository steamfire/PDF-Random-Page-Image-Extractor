#!/bin/zsh
# Extract random PDF pages from pdfs
# convert to JPEG
# overlay original ODF name and page number on JPEG

PDFINPUTFILEPATH="$1"
PDFINPUTFILENAME=$PDFINPUTFILEPATH:t

OUTPUTDIRECTORY="/Users/admin/Dropbox/BalloonConsulting/PDF\ Workflow\ Redevelopment\ Scratch\ Folder\ 2020/PDF\ pages\ to\ screensaver/"

#Count pages in PDF
PAGECOUNT=`mdls -raw -name kMDItemNumberOfPages $PDFINPUTFILEPATH`
echo -n "Pages $PAGECOUNT \n"

RANDOMPAGENUMBER=`jot -r 1 1 $PAGECOUNT`
echo -n "Page Number$RANDOMPAGENUMBER \n"

echo -n "out dir: $OUTPUTDIRECTORY\n"

echo -n "$PDFINPUTFILEPATH $OUTPUTDIRECTORY$PDFINPUTFILENAME.jpg\n"

pdftocairo -jpeg -jpegopt optimize=y -f 2 -l 2 '$PDFINPUTFILEPATH $OUTPUTDIRECTORY$PDFINPUTFILENAME.jpg'
