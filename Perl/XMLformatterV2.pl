#!/usr/bin/perl -w

#useful if scraper doesn't print sent/received XML in clear format, takes hex dump and prints chars

use warnings;
use strict;

my ($fileIn, @fileLines, $line, $indentCount, $tracker, $lineCharacter, @lineCharacters, $debug, $result, $ignoreWhitespace);

$debug = 0;

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


$result = globalizeReferences($result);


if($debug)
{
	print "Start\n";
	print $result;
	print "End\n";
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
		
		#if end of line is reached
		if($tempCharacter eq "\n")
		{
			#return false
			$result = 0;
			last;
		}
		else
		{
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
					last;
				}
			}
		}
	}
	
	return $result;
}

sub checkMismo
{
	my $result = 0;
	
	my $tempCharacter = " ";

	#if no mismo:
	for(my $y=0; $y < 6; $y++)
	{
		$tempCharacter = $lineCharacters[($tracker+1+$y)];
		
		#if end of line is reached
		if($tempCharacter eq "\n")
		{
			#return false
			$result = 0;
			last;
		}
		else
		{
			#continue checking for mismo
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
				if(!($tempCharacter eq ":"))
				{
					$result = 0;
				}
				else
				{
					$result = 1;
					last;
				}
			}
		}
	}
	
	return $result;
}

sub globalizeReferences
{
	my $globalResult = $_[0];
	
	#globalize xmlns:gse="http://www.datamodelextension.org"
	$globalResult = globalizeReference($globalResult, "xmlns:gse=\"http://www.datamodelextension.org\"");
	
	#globalize MISMOReferenceModelIdentifier="3.3.0299"
	#$globalResult = globalizeReference($globalResult, "MISMOReferenceModelIdentifier=\"3.3.0299\"");
	
	return $globalResult;	
}

sub globalizeReference
{
	my $globalizedResult = $_[0];
	my $reference = $_[1];
	
	$globalizedResult = injectReference($globalizedResult, $reference);
	
	$globalizedResult = removeReference($globalizedResult, $reference);
	
	return $globalizedResult;
}

sub injectReference
{
	my $injectResult = $_[0];
	my $injectReference = $_[1];
	
	my $complete = 0;
	
	my @fileCharacters;
	my $fileCharacter = " ";
	
	my $beforeCharacters = " ";
	my $afterCharacters = " ";
	
	my $targetLine = 0;
	my $skip = 0;
	
	my $tempCharacter;
	
	#inject reference into message
		#split result into array of characters
	@fileCharacters = split(//, $injectResult);
	
	#walk through array of characters
	for(my $x = 0; $x < scalar(@fileCharacters); $x++)
	{
		#pull single value of array
		$fileCharacter = $fileCharacters[$x];
	
		#if not complete
		if($complete == 0)
		{
		
			if( $targetLine == 1 )
			{
				#if less than the length of the reference from the end of the injectResult
				if( ( $x+length($injectReference) ) < scalar(@fileCharacters) )
				{
					$tempCharacter = substr($injectResult, $x, length($injectReference));
				
					#if reference already exists
					if( $tempCharacter eq $injectReference )
					{
						#set complete as true
						$complete = 1;
						#abort
						last;
					}
					#else if '>' is found
					elsif($fileCharacters[($x)] eq '>')
					{
						#grab before
						$beforeCharacters = substr($injectResult, 0, $x);
						
						#grab after
						$afterCharacters = substr($injectResult, $x, scalar(@fileCharacters)-$x+1);
						
						#write before
						$injectResult = $beforeCharacters;
						
						#if previous character is not a space
						if( !($fileCharacters[($x-1)] eq ' ') )
						{
							#write space character
							$injectResult = $injectResult.' ';
							#update x
							$x++;
						}
						
						#Write reference
						$injectResult = $injectResult.$injectReference;
						#update x
						$x = $x + length($injectReference);
						
						#write after
						$injectResult = $injectResult.$afterCharacters;
						
						#set complete as true
						$complete = 1;
						$targetLine = 0;
						#abort
						last;
					}
				}
			}
			#if skip is true
			elsif( $skip == 1 )
			{
				#if end of line is reached
				if( $fileCharacter eq "\n" )
				{
					#set skip to false
					$skip = 0;
				}
			}
			#find message line
			elsif( $fileCharacter eq '<' )
			{
				$tempCharacter = substr( $injectResult, $x+1, 13 );
				
				#check following characters for "mismo:MESSAGE"
				if( $tempCharacter eq "mismo:MESSAGE" )
				{
					$targetLine = 1;
				}
				else
				{
					$skip = 1;
				}
			}
			
		}
		#else is complete
		else
		{
			#stop processing
			last;
		}
	}
	
	return $injectResult;
}

sub removeReference
{
	my $removeResult = $_[0];
	my $removedReference = $_[1];
	
	my $remove = 0;
	my $targetLine = 0;
	
	my @fileCharacters;
	my $fileCharacter = " ";
	
	my $beforeCharacters = " ";
	my $afterCharacters = " ";
	
	my $tempCharacter = " ";

	#remove reference from rest of file
		#split result into array of characters
	@fileCharacters = split(//, $removeResult);
	
	#walk thourgh array of characters
	for(my $x = 0; $x < scalar(@fileCharacters); $x++)
	{
		#pull single value of array
		$fileCharacter = $fileCharacters[$x];
		
		#if remove is false
		if( $targetLine == 1 )
		{
			#if end of target line is found
			if( $fileCharacter eq '>' )
			{
				#set remove to true
				$remove = 1;
				#set targetline to false
				$targetLine = 0;
			}
		}
		elsif( $remove == 0 )
		{
			#find message line
			if( $fileCharacter eq '<' )
			{
				$tempCharacter = substr( $removeResult, $x+1, 13 );
				
				#check following characters for "mismo:MESSAGE"
				if( $tempCharacter eq "mismo:MESSAGE" )
				{
					$targetLine = 1;
				}
			}
		}
		#else, remove is true
		else
		{	
			#if less than the length of the reference from the end of the line
			if( ( $x ) < (length($removeResult)-length($removedReference)) )
			{
				#if reference is found
				if( substr($removeResult, $x, length($removedReference)) eq $removedReference )
				{
					#grab before
					$beforeCharacters = substr($removeResult, 0, $x-1);
					
					#update x to skip reference
					$x = $x+length($removedReference);
					
					#grab after, skipping reference
					$afterCharacters = substr($removeResult, $x, length($removeResult)-$x+1);
					
					#write before
					$removeResult = $beforeCharacters;
					
					#write after
					$removeResult = $removeResult.$afterCharacters;
				}
			}
		}		
	}
	
	return $removeResult;
}
