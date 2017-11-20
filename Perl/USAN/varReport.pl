#!/usr/bin/perl
###############################################################################
# File:   varReport.pl
# Author: Ryan Riordan
###############################################################################

###declarations
my $line;
my $uVarStr;
my @uVarArr;
my @aVarArr;
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

while( ($line = <APP>) && !($line =~ /^\[[A-Za-z]+\s+\w+]/) )
{
   if ( $line =~ /^u_/ )
   {
      ($uVarStr) = split /,/, $line, 2;
      push( @uVarArr, $uVarStr );
   }
   if ( $line =~ /^a_/ )
   {
      ($aVarStr) = split /,/, $line, 2;
      push( @aVarArr, $aVarStr );
   }
}

printf "U_VAR NAME                  REF COUNT\n";
printf "----------                  ---------\n";

$begCodePos = tell APP;
while( $uVarStr = shift(@uVarArr) )
{
   $refCount = 0;
   while( $line = <APP> )
   {
       if ( $line =~ /$uVarStr(\s|,|=|\)|\n)/ )
       {
          $refCount++;
       }
   }

   printf "%-32s   %2d\n", $uVarStr, $refCount;

   seek APP, $begCodePos, 0;
}

printf "\n\n";
printf "A_VAR NAME                  REF COUNT\n";
printf "----------                  ---------\n";

while( $aVarStr = shift(@aVarArr) )
{
   $refCount = 0;
   while( $line = <APP> )
   {
       if ( $line =~ /$aVarStr(\s|,|=|\)|\n)/ )
       {
          $refCount++;
       }
   }

   printf "%-32s   %2d\n", $aVarStr, $refCount;

   seek APP, $begCodePos, 0;
}

printf "\nDone, now leave me alone!\a";

close(APP);