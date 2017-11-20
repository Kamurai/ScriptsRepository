#!/usr/bin/perl

use strict; #variables must be declared

my ($file, @lines, $line, $isComment); #"my variables":  variable declaration

$file = shift; #$ indicates a variable
#defaulted to @argv
#@argv is populate by  arguments given to the script:  formatapp.pl pikachu.txt squirtle.js charmander.pl
#shift gets and removes the first element of the array
$isComment = "";

open(DATAIN, $file) || die "Could not open file $file ($!)";  #open 2nd argument (file) and write to first argument
@lines = <DATAIN>; #@ indicates and array
close(DATAIN); #close file

foreach $line (@lines) #for each element of @, henceforth referred to as $
{
#=~ indicates a "pattern match":  variable =~ pattern
	if(($line =~ /(.+)(\/\*.*)/) && (!$isComment)) #if $ is equal to any any character occuring at least once followed by '/', followed by '*', followed by any number of any any character AND is not already in a comment
	{
		$isComment = "yes";
		$line = formatAppCode($1, "")."$2\n";
		print "This should fail when run against manager:  $line\n";
	}
	elsif(($line =~ /^(\/\*.*)/) && (!$isComment)) #if $ is not equal to '/', '*', followed by any number of any any character AND is not already a comment
	{
		$isComment = "yes";
	}
	elsif(($line =~ /(.*)?\/\*/) && ($isComment)) #if $ is equal to 0 or 1 occurence of any number of any character followed by '/', followed by '*' AND is already a comment
	{
		print "Nested block comments are not allowed.\n\t$line";
		exit 2;
	}
	elsif (($line =~ /(.*\*\/)(.+)/) && ($isComment)) #if $ is equal to any number of any character followed by '*', followed by '/', all followed by at least one of any characters
	{
		$isComment = "";
		$line = $1.formatAppCode($2, "")."\n";
		print "This should fail when run against manager:  $line\n";
	}
	elsif (($line =~ /(.*\*\/)$/) && ($isComment)) #if $ is equal to any number of any character, followed by '*', followed by '/', followed by the end of line.
	{
		$isComment = "";
		$line = "$1\n";
	}
	elsif (($line =~ /(.*)?\*\/(.*)?/) && (!$isComment)) #if $ is equal to any number of any character ocurring 0 or once, followed by '*', followed by '/', all followed by any number of any character ocurring 0 or once
	{
		print "Cannot end comment before starting it, retard.\n\t$line";
		exit 4;
	}
	elsif ($isComment)
	{
	}
	elsif ($line =~ /^;.*/) #if $ is equal to the beginning of a line, followed by ';' followed by any number of any characters
	{
	}
	elsif ($line =~ /^(.*;)(.+)+/) #if $ is equal to the beginning of a line, followed by any number of any characters followed by ';', all followed by at least one '.' occuring at least once
	{
		if(substr($line, index($line, ";")) =~ /[a-zA-Z]{2,3}\d{2,}/) #if $ is equal to a letter followed by 2 or 3 characters that are numbers #pivot, I have no actual idea
		{
			$line = formatAppCode(substr($line, 0, index($line, ";")), "").substr($line, index($line, ";"));
		}
		else #line of code is treated AS IF a general line of code
		{
			$line = formatAppCode($line, "1")."\n";
		}
	}
	else #line of code is a general line of code.
	{
		$line = formatAppCode($line, "1")."\n";
	}
}

open(DATAOUT, ">$file"); #.out");
foreach $line (@lines)
{
	print DATAOUT "$line";
}
close DATAOUT;

sub formatAppCode
{
	my ($line, $keepItShort, $tempStr1, $tempStr2, $returnStr);
	$line = $_[0];
	$keepItShort = $_[1];
	$line =~ s/\n//;
	if($line =~ /^(\[.*\].*$)/) #if $ is equal to the begining of line followed by '[', followed by any number of any characters, followed by ']' followed by any number of any characters until end of line
	#in cases such as [PROMPT promptCell]
	{
		$tempStr1 = $1;
		$tempStr1 =~ s/\s+$//;
		if($keepItShort)
		{
			$returnStr = $tempStr1; #
		}
		else
		{
			$returnStr = sprintf("%-67s", $tempStr1); #prints temp string left justified up to 67 characters as a string
		}
	}
	elsif($line =~ /^((?:a_|u_|c_).+\,(?:name|string|number|bignumber|boolean|cell|prompt|dynaprompt|enum|phone|port|portlist|todgroup|peg|peglist),?[\d|\s]*?)(=.*)/i)
	{
		$tempStr1 = $1;
		$tempStr2 = $2;
		$tempStr1 =~ s/\s+$//;
		$tempStr2 =~ s/\s+$//;
		if(length($tempStr1) > 40)
		{
			$tempStr1 = $tempStr1." ";
		}
		else
		{
			$tempStr1 = sprintf("%-40s", $tempStr1);
		}
		if((length($tempStr2) < 27) && !($keepItShort))
		{
			$tempStr2 = sprintf("%-27s", $tempStr2);
		}
		$returnStr = $tempStr1.$tempStr2;
	}
	elsif($line =~ /(.*)(=.*)/)
	{
		$tempStr1 = $1;
		$tempStr2 = $2;
		$tempStr1 =~ s/\s+$//;
		$tempStr2 =~ s/\s+$//;
		if(length($tempStr1) > 32)
		{
			$tempStr1 = $tempStr1." ";
		}
		else
		{
			$tempStr1 = sprintf("%-32s", $tempStr1);
		}
		if((length($tempStr2) < 35) && !($keepItShort))
		{
			$tempStr2 = sprintf("%-35s", $tempStr2);
		}
		$returnStr = $tempStr1.$tempStr2;
	}
	else
	{
		$returnStr = $line;
	}
	return $returnStr;
}
