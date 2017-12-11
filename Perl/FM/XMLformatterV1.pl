#!/usr/bin/perl -w

#useful if scraper doesn't print sent/received XML in clear format, takes hex dump and prints chars

use warnings;
use strict;

my ($fileIn, @fileLines, $line, $indentCount, $tracker, $lineCharacter, @lineCharacters, $debug, $result, $ignoreWhitespace);

$debug = 1;

if($debug)
{
	print "First.\n\n";
}

$fileIn = shift;
$indentCount = 0;
$lineCharacter = "";
$tracker = 0;
@lineCharacters = "";

$result = "";
$ignoreWhitespace = 1;

if($debug)
{
	print "Second.\n\n";
}

#open the targeted file
open(OUTFILEIN, $fileIn);
@fileLines = <OUTFILEIN>;
close(OUTFILEIN);

if($debug)
{
	print "Third.\n\n";
}

#for each line in the file
foreach $line (@fileLines)
{
	if($debug == 2)
	{
		$result = $result."Line: ";
	}

	#split line into array of characters
	@lineCharacters = split(//, $line);
	
	#walk thourgh array of characters
	for($tracker = 0; $tracker < scalar(@lineCharacters); $tracker++)
	{
		#pull single value of array
		$lineCharacter = $lineCharacters[$tracker];
		
		#if whitespace
		if( ($lineCharacter eq ' ' || $lineCharacter eq "\t") )
		{
			#if not ignoring whitespace
			if( $ignoreWhitespace == 0 )
			{
				#add character to result
				$result = $result.$lineCharacter;
			}
			
		}
		#if '<', then at a tag
		elsif($lineCharacter eq '<')
		{
			#stop ignoring whitespace
			$ignoreWhitespace = 0;
			
			if($debug == 2)
			{
				$result = $result."Current indent count: ";
				$result = $result.$indentCount;
			}
		
			#if next character is not the last character
			if(($tracker+1) < scalar(@lineCharacters))
			{
				#if '/', then current tag is ending tag
				if(@lineCharacters[($tracker+1)] eq '/') # '/'
				{
					#decrease indent count
					$indentCount--;
					
					#If previous character is whitespace or first character
					if( 
						(@lineCharacters[($tracker-1)] eq ' ') ||
						(@lineCharacters[($tracker-1)] eq "\t") || 
						($tracker == 0)
						)
					{
						#insert tabs based on indent count
						for(my $x=0; $x < $indentCount; $x++)
						{
							$result = $result."\t";
						}
						
					}
					
					
					
					#add character to result
					$result = $result.$lineCharacter.'/';
					$tracker++;
					
					#check for existing namespaces
					if( checkNamespaces() == 0 )
					{
						#if no mismo
						if( checkMismo() == 0 )
						{
							$result = $result."mismo:";					
						}
					}
				}
				#else if ?, then start of metadata tag
				elsif(@lineCharacters[($tracker+1)] eq '?')
				{
					#add character to result
					$result = $result.$lineCharacter;
				}
				#else if a comment
				elsif(@lineCharacters[($tracker+1)] eq '!')
				{
					#insert tabs based on indent count
					for(my $x=0; $x < $indentCount; $x++)
					{
						$result = $result."\t";
					}
					
					#add character to result
					$result = $result.$lineCharacter;
					
				}
				else #starting tag
				{
					#insert tabs based on indent count
					for(my $x=0; $x < $indentCount; $x++)
					{
						$result = $result."\t";
					}
					
					#increase indent count
					$indentCount++;
					
					#add character to result
					$result = $result.$lineCharacter;
					
					#check for existing namespaces
					if( checkNamespaces() == 0 )
					{
						#if no mismo
						if( checkMismo() == 0 )
						{
							$result = $result."mismo:";					
						}
					}
				}
			}
			else
			{
				$result = $result."error!";
			}
		}
		#else if '>'
		elsif($lineCharacter eq '>')
		{
			#check if previous character was a '/'
			if( @lineCharacters[($tracker-1)] eq '/' )
			{
				$indentCount--;			
			}		
		
			#add character to result
			$result = $result.$lineCharacter;
			
			#if not the last character in the line
			if(($tracker+1) < scalar(@lineCharacters))
			{
				#if next character is '<' and not "\n"
				if((@lineCharacters[($tracker+1)] eq '<') && (@lineCharacters[($tracker+1)] eq "\n"))
				{
					#add eol to result
					$result = $result."\n";
				}
			}
			#if at end of line array
			elsif(($tracker+1) == scalar(@lineCharacters))
			{
				#add eol to result
				$result = $result."\n";
			}
		}
		elsif($lineCharacter eq "\n")
		{
			#start ignoring whitespace
			$ignoreWhitespace = 1;
			
			#add eol to result
			$result = $result."\n";
		}
		else
		{
			if( !($lineCharacter eq ' ' || $lineCharacter eq "\t") )
			{
				#add character to result
				$result = $result.$lineCharacter;
			}
		}
	}
   	
}

if($debug)
{
	print $result;
}

# write result to file
open(my $writeFile, '>', $fileIn."_adjusted.xml");
print $writeFile $result;
close $writeFile;


sub checkNamespaces
{
	my $result = 0;
	
	if( checkGSE() == 1 )
	{
		$result = 1;
	}
	else
	{
		$result = 0;
	}	
	
	return $result;
}

sub checkGSE
{
	my $result = 0;
	
	my $tempCharacter = "";

	#if no gse:
	for(my $y=0; $y < 4; $y++)
	{
		$tempCharacter = $lineCharacters[($tracker+1+$y)];
		
		if($y == 0)
		{
			if(!($tempCharacter eq 'g'))
			{
				$result = 0;
			}
		}
		elsif($y == 1)
		{
			if(!($tempCharacter eq 's'))
			{
				$result = 0;
			}
		}
		elsif($y == 2)
		{
			if(!($tempCharacter eq 'e'))
			{
				$result = 0;
			}
		}
		elsif($y == 3)
		{
			if(!($tempCharacter eq ':'))
			{
				$result = 0;
			}
			else
			{
				$result = 1;
			}
		}
	}
	
	return $result;
}

sub checkMismo
{
	my $result = 0;
	
	my $tempCharacter = "";

	#if no mismo:
	for(my $y=0; $y < 6; $y++)
	{
		$tempCharacter = $lineCharacters[($tracker+1+$y)];
		
		if($y == 0)
		{
			if(!($tempCharacter eq 'm'))
			{
				$result = 0;
			}
		}
		elsif($y == 1)
		{
			if(!($tempCharacter eq 'i'))
			{
				$result = 0;
			}
		}
		elsif($y == 2)
		{
			if(!($tempCharacter eq 's'))
			{
				$result = 0;
			}
		}
		elsif($y == 3)
		{
			if(!($tempCharacter eq 'm'))
			{
				$result = 0;
			}
		}
		elsif($y == 4)
		{
			if(!($tempCharacter eq 'o'))
			{
				$result = 0;
			}
		}
		elsif($y == 5)
		{
			if(!($tempCharacter eq ':'))
			{
				$result = 0;
			}
			else
			{
				$result = 1;
			}
		}
	}
	
	return $result;
}

