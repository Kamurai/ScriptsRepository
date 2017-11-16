#!/usr/bin/perl

use strict;

my ($file, @lines, $line, $fileContents, @blocks, $block);
my ($time, $callSeq, $app, $entry, $choiceCell, $menuCell, $grammar, $sivrEntry, $seqNum, $confScore);
my ($tempNum);

$file = shift;

open(DATAIN, $file) || die "Could not open file $file ($!)";
read(DATAIN, $fileContents, -s $file);
close(DATAIN);

$block = "";

@blocks = split(/\d\d\/\d\d\/\d\d/, $fileContents);

foreach $block (@blocks)
{
	@lines = split(/\n/, $block);
	foreach $line (@lines)
	{
		if($line =~ /(?:menuLogCollectReply).*http:(.*)\.grxml,(.*),\"(.*)\"/i)
		{
			#print "$line\n";
			$tempNum = rindex($1, "/");
			$grammar = substr($1, $tempNum + 1);
			$tempNum = rindex($2, ",");
			$entry   = substr($2, $tempNum + 1);
			$sivrEntry = $3;
			#print "Grammar:  $grammar\nEntry:  $entry\nSIVR Entry:  $sivrEntry\n";
		}
		if($line =~ / (\d\d:\d\d:\d\d\.\d\d\d)/)
		{
			$time = $1;
		}
		#28,0 II:00, Ani:6785590504, Dst:2140182, Bill:, Dnis:2140182, Ent:5424180469438151, SpeechRecStatus:Unknown, ConfScore: 0
		elsif($line =~ /\#(\d+).*Ent:([0-9a-zA-Z*\#]*), Speech.*ConfScore:\s+(\d+)/i)
		{
			$seqNum = $1;
			if($entry ne $2)
			{
				$entry = $2;
				$confScore = $3;				
			}
			#print "SeqNum:  $seqNum\nEntry:  $entry\n";
		}
		elsif($line =~ /A:\d+-(\w+) C:\d+-(\w+) \(choice\) P:(\w+) \(menu\).*/i)
		{
			$app = $1;
			$choiceCell = $2;
			$menuCell = $3;
			if($sivrEntry)
			{
				printf("%s\t%s\t%-20s\t%-32s\t%-32s\t%3s\t%32s\t%s\t%s\n", $time, $seqNum, $app, $menuCell, $choiceCell, $confScore, $entry, $grammar, $sivrEntry);
				$sivrEntry = "";
				$grammar = "";
				$menuCell = "";
				$choiceCell = "";
				$entry = "";
				$confScore = "0";
			}
			else
			{
				printf("%s\t%s\t%-20s\t%-32s\t%-32s\t%32s\t%3s\t%s\n", $time, $seqNum, $app, $menuCell, $choiceCell, $confScore, $entry);
				$sivrEntry = "";
				$grammar = "";
				$menuCell = "";
				$choiceCell = "";
				$entry = "";
				$confScore = "0";
			}
		}
	}
}