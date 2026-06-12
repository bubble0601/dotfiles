#!/usr/bin/perl
$latex         = 'platex -synctex=1 -halt-on-error -file-line-error %O %S';
$bibtex        = 'pbibtex %O %B';
#$dvipdf        = 'dvipdfmx %O %S';
$dvipdf        = 'dvipdfmx %O -o %D %S';
$pdf_mode      = 3; # use dvipdf
$pdf_update_command = 'open -a Preview %S';
# Skim.appで開く場合は下のように書く
#$pdf_update_command = 'open -ga /Applications/Skim.app';
