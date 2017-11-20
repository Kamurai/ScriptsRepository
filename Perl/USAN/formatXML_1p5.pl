#!/usr/bin/perl -w

#useful if scraper doesn't print sent/received XML in clear format, takes hex dump and prints chars

use warnings;
use strict;

my ($fileIn, @fileLines, $line);

$fileIn = shift;

open(OUTFILEIN, $fileIn);
@fileLines = <OUTFILEIN>;
close(OUTFILEIN);

foreach $line (@fileLines)
{
  	if($line =~ /^\| ((?:[0-9a-fA-F ]{2} ){1,16}) \| (.{16}) \|$/)
   	{
   	    my @hexVars = split(/\s/, $1);
   	    foreach my $hexVar (@hexVars)
   	    {
   	        print chr(hex $hexVar);
			
			if($hexVar eq "3e")
			{
				print "\n";
				
			}
   	    }
   	}
   	else
   	{
   	    print "$line";
   	}
}
