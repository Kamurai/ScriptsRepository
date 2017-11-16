#!/usr/bin/perl -w

#useful if scraper doesn't print sent/received XML in clear format, takes hex dump and prints chars

use warnings;
use strict;

my ($fileIn, @fileLines, $line, $spaces, $count, $tracker, $hexVar, @hexVars);

$fileIn = shift;
$spaces = "";
$count = 0;
$hexVar = "";
$tracker = 0;
@hexVars = "";

open(OUTFILEIN, $fileIn);
@fileLines = <OUTFILEIN>;
close(OUTFILEIN);

foreach $line (@fileLines)
{
  	if($line =~ /^\| ((?:[0-9a-fA-F ]{2} ){1,16}) \| (.{16}) \|$/)
   	{
   	    @hexVars = split(/\s/, $1);
		for($tracker = 0; $tracker < @hexVars; $tracker++)
   	    {
			$hexVar = $hexVars[$tracker];
			
			if($hexVar eq "3c")
			{
				if(($tracker+1) < scalar(@hexVars))
				{
					if($hexVars[($tracker+1)] eq "2f")
					{
						$spaces = substr $spaces, 0, $count;
						$count -= 4;
						print "\n";
						print $spaces;
						print chr(hex $hexVar);
					}
					elsif($hexVars[($tracker+1)] eq "3f")
					{
						$spaces = substr $spaces, 0, $count;
						$count -= 4;
						print "\n";
						print $spaces;
						print chr(hex $hexVar);
					}
					else
					{
						print "\n";
						print $spaces;
						print chr(hex $hexVar);
						$spaces = $spaces . "    ";
						$count += 4;
					}
				}
				else
				{
					print "\n";
					print $spaces;
					print chr(hex $hexVar);
				}
			}
			elsif($hexVar eq "3e")
			{
				print chr(hex $hexVar);
				if(($tracker+1) < scalar(@hexVars))
				{
					if(!($hexVars[($tracker+1)] eq "3c") && !($hexVars[($tracker+1)] eq "0a"))
					{
						
						print "\n";
						$spaces = $spaces . "    ";
						$count += 4;
						print $spaces;
						$spaces = substr $spaces, 0, $count;
						$count -= 4;
					}
				}
			}
			else
			{
				print chr(hex $hexVar);
			}
   	    }
   	}
   	else
   	{
				
   	    print "$line";
   	}
}
