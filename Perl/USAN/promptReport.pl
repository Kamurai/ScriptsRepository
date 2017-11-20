#!/usr/bin/perl
###############################################################################
# File:   promptReport.pl
# Author: Kevin A Todd (bastardized version of varReport.pl by Ryan Riordan)
###############################################################################

###declarations
my $line;
my $promptVar;
my $compVar;
my @promptArr;
my @promptArrNoDups;
my $begCodePos;
my $refCount;

###get user input
$appFile  = shift(@ARGV) or die "No target app file.  $!\n";
open(APP, "<$appFile") or die "Unable to open app file.  $!\n";

if ($outFile = shift(@ARGV))
{
   open(OUTPUT, ">$outFile") or die "Unable to open output file:  $!\n";
   select(OUTPUT);
} 
else
{
   select(STDOUT);
}
$begCodePos = tell APP;

###get all prompt vars
while( ($line = <APP>) )
{
   chomp($line);
   if ( $line =~ /^pr_/ )
   {
      ($promptVar) = split /=/, $line, 2;
      ($promptVar) = split / /, $promptVar, 2;
      push( @promptArr, $promptVar );
   }
}
seek APP, $begCodePos, 0;

###get rid of duplicates
PROMPT:foreach $promptVar (@promptArr)
{
   foreach $compVar (@promptArrNoDups)
   {
      if ( $promptVar eq $compVar )
      {
         next PROMPT;
      }
   }
   push ( @promptArrNoDups, $promptVar );
}

###print output headers
printf "PROMPT NAME                 REF COUNT\n";
printf "-----------                 ---------\n";

###parse file (a lot) and output counts
foreach $promptVar (@promptArrNoDups)
{
   $refCount = 0;
   while($line = <APP> )
   {
      if ( $line =~ /=$promptVar(\s+\n|\n)/ )
      {
         $refCount++;
      }
   }

   printf "%-32s   %2d\n", $promptVar, $refCount;

   seek APP, $begCodePos, 0;
}

printf "\nDone, now leave me alone!\a";

close(APP);
