#!/usr/bin/perl

use strict;
use File::Find::Rule;

my %traceHash = ();

Main(shift);

sub Main
 {
    my $searchSpot = $_[0];
    
    if(-d $searchSpot)
    {        
        printf("Searching \"%s\" for *.txt files...\n", $searchSpot);
        my @files = File::Find::Rule->file()->name(qr/\.(rol|out|txt)/i)->in($searchSpot);
        foreach my $file (@files)
        {
            ProcessFile($file);
        }
    }
    elsif(-e $searchSpot)
    {
        ProcessFile($searchSpot);
    }
    
    else
    {
        print "Not a valid starting spot...\n";
        exit 1;
    }
    
    PrintTraces();
    exit 0;    
 }


sub ProcessFile
{
    my $file = $_[0];
    
    printf("Processing \"%s\"...\n", $file);
    
    my ($fileContents, $time, $callSeq, $app, $entry, $choiceCell, $menuCell, $grammar, $sivrEntry, $confScore);
    
    open(DATAIN, $file) || die "Could not open file \"$file\" ($!)\n";
    read(DATAIN, $fileContents, -s $file);
    close(DATAIN);
    
    my @blocks = split(/\n{2}/, $fileContents);
    
    foreach my $block (@blocks)
    {
#        print STDERR "-----------------------------------------------------------------------------------------------------\n";
#        print STDERR "$block\n";        
#        print STDERR "-----------------------------------------------------------------------------------------------------\n";
    
        undef $time;
        undef $callSeq;
        undef $app;
        undef $entry;
        undef $choiceCell;
        undef $menuCell;
        undef $grammar;
        undef $sivrEntry;
        undef $confScore;
    
    	my @lines = split(/\n/, $block);
    	foreach my $line (@lines)
    	{
    		if($line =~ /(?:menuLogCollectReply,)\d{2}(\d{2})-(\d{2})-(\d{2})\s(\d{2}:\d{2}:\d{2}\.\d{3}),\d+,\d+,\d+,\d+,(\d+),(\w+),(\w+),\d+,http:\/\/.*\/(.*)\.grxml,.*,(\d{1,3}),(\w*),(\"\w*\"),/i)
    		{
    		    $time = $2."/".$3."/".$1." ".$4;
    		    $callSeq = $5;
    		    $app = $6;
    		    $menuCell = $7;
    		    $grammar = $8;
    		    $confScore = $9;
    		    $entry = $10;
    		    $sivrEntry = $11;		    
    		    
    			#printf("LINE:  %s\n\tTime:  %s\n\tCall Seq:  %s\n\tApp:  %s\n\tMenu:  %s\n\tGrammar:  %s\n\tConf Score:  %s\n\tEntry:  %s\n\tSIVR Entry:  %s\n", $line, $time, $callSeq, $app, $menuCell, $grammar, $confScore, $entry, $sivrEntry);
    		}
    		elsif($line =~ /(\d{2}\/\d{2}\/\d{2}\s\d{2}:\d{2}:\d{2}\.\d{3})/)
    		{
    			$time = $1;
    		}
    		elsif($line =~ /^\s\#(\d+).*Ent:([\w\*\#\.]*), Speech.*ConfScore:\s+(\d+)$/i)
    		{
    			$callSeq = $1;
   				$entry = $2;
   				$confScore = $3;
   				#printf("LINE:  %s\n", $line);
    		}
    		elsif($line =~ /A:\d+-(\w+) C:\d+-(\w+) \(choice\) P:(\w+) \(menu\).*/i)
    		{
    			$app = $1;
    			$choiceCell = $2;
    			$menuCell = $3;
    		}
    	}

    	if($menuCell && $callSeq)
    	{
    	    if(exists $traceHash{$callSeq}{$time})
    	    {
      	        $traceHash{$callSeq}{$time}{"APP"}        =($app ? $app : $traceHash{$callSeq}{$time}{"APP"});
       	        $traceHash{$callSeq}{$time}{"ENTRY"}      =($entry ? $entry : $traceHash{$callSeq}{$time}{"ENTRY"});
       	        $traceHash{$callSeq}{$time}{"CHOICECELL"} =($choiceCell ? $choiceCell : $traceHash{$callSeq}{$time}{"CHOICECELL"});
       	        $traceHash{$callSeq}{$time}{"MENUCELL"}   =($menuCell ? $menuCell : $traceHash{$callSeq}{$time}{"MENUCELL"});
       	        $traceHash{$callSeq}{$time}{"GRAMMAR"}    =($grammar ? $grammar : $traceHash{$callSeq}{$time}{"GRAMMAR"});
       	        $traceHash{$callSeq}{$time}{"SIVRENTRY"}  =($sivrEntry ? $sivrEntry : $traceHash{$callSeq}{$time}{"SIVRENTRY"});
       	        $traceHash{$callSeq}{$time}{"CONFSCORE"}  =($confScore ? $confScore : $traceHash{$callSeq}{$time}{"CONFSCORE"});
    	    }
    	    else
    	    {
        	    $traceHash{$callSeq}{$time}{"APP"}        =$app;
        	    $traceHash{$callSeq}{$time}{"ENTRY"}      =$entry;
        	    $traceHash{$callSeq}{$time}{"CHOICECELL"} =$choiceCell;
        	    $traceHash{$callSeq}{$time}{"MENUCELL"}   =$menuCell;
        	    $traceHash{$callSeq}{$time}{"GRAMMAR"}    =$grammar;
        	    $traceHash{$callSeq}{$time}{"SIVRENTRY"}  =$sivrEntry;
        	    $traceHash{$callSeq}{$time}{"CONFSCORE"}  =$confScore;
    	    }
    	}
    }
}

sub PrintTraces
{
    foreach my $call (sort keys %traceHash)
    {
        foreach my $menuTime (sort keys $traceHash{$call})
        {
            printf("%s\t%s\t%-20s\t%-32s\t%-32s\t%3s\t%32s\t%s\t%s\n", $call, $menuTime,
                    $traceHash{$call}{$menuTime}{"APP"}, $traceHash{$call}{$menuTime}{"MENUCELL"},
                    $traceHash{$call}{$menuTime}{"CHOICECELL"}, $traceHash{$call}{$menuTime}{"CONFSCORE"},
                    $traceHash{$call}{$menuTime}{"ENTRY"}, $traceHash{$call}{$menuTime}{"GRAMMAR"},
                    $traceHash{$call}{$menuTime}{"SIVRENTRY"});
        }
        printf("\n\n\n");
    }
}