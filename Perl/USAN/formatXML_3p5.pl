#!/usr/bin/perl -w

#useful if scraper doesn't print sent/received XML in clear format, takes hex dump and prints chars

use warnings;
use strict;

my ($fileIn, @fileLines, $line, $spaces, $count, $tracker, $hexVar, @hexVars, $tagFlag);

$fileIn = shift;
$spaces = "";
$count = 0;
$hexVar = "";
$tracker = 0;
@hexVars = "";
$tagFlag = 0;

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
			if($tagFlag == 1)
			{
				$count -= 4;
				$spaces = substr $spaces, 0, $count;
				print "\n";
				print $spaces;
				print chr(hex $hexVar);
				$tagFlag = 0;
			}
			elsif($hexVar eq "3c") # '<'
			{
				if(($tracker+1) < scalar(@hexVars))
				{
					# pivot: if '/' occurs on next line, then this does not apply
						# you can't check for tracker+1 equalling hexVars length as this could apply to "<x" as well as "</"
					if($hexVars[($tracker+1)] eq "2f") # '/'
					{
						$count -= 4;
						$spaces = substr $spaces, 0, $count;
						print "\n";
						print $spaces;
						print chr(hex $hexVar);
					}
					elsif($hexVars[($tracker+1)] eq "3f") # '?'
					{
						$count -= 4;
						$spaces = substr $spaces, 0, $count;
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
				elsif(($tracker+1) == scalar(@hexVars))
				{
					$tagFlag = 1;
				}
				else
				{
					print "\n";
					print $spaces;
					print chr(hex $hexVar);
				}
			}
			elsif($hexVar eq "3e") # '>'
			{
				print chr(hex $hexVar);
				if(($tracker+1) < scalar(@hexVars))
				{
					if(!($hexVars[($tracker+1)] eq "3c") && !($hexVars[($tracker+1)] eq "0a")) # '<' '/n'
					{
						
						print "\n";
						#$spaces = $spaces . "    ";
						#$count += 4;
						print $spaces;
						#$spaces = substr $spaces, 0, $count;
						#$count -= 4;
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
