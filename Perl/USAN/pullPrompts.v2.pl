#!/usr/bin/perl -w

use strict;
use LWP::Simple;

my ($fileName, $fileContents, @langs, $getVerbiage);
my %promptHash = ();
my %allPrompts = ();

$getVerbiage = 1;

$fileName = shift;

printPrompts(getPrompts(getApp($fileName)));

sub getApp
{
    my $fileName = $_[0];
    my ($fileContents);
    open(APPIN, "<$fileName") or die "Couldn't open $fileName($!)\n";
    read(APPIN, $fileContents, -s $fileName);
    close(APPIN);
    return $fileContents;
}

sub getPrompts
{
    my $fileContents = $_[0];
    my @blocks = split(/\[/, $fileContents);
    foreach my $block (@blocks)
    {
        my @lines = split(/\n/, $block);
        if($#lines > 0 && $lines[0] =~ /^prompts\s+(\w+(?:\s\d{1,2})?)]/i)
        {
            my $langVers = $1;
            push(@langs, $langVers);
            foreach my $line (@lines)
            {
                if($line =~ /^([a-zA-Z0-9_-]+)(?:\s+)?\=(\w*)[\s\n]?/i)
                {
                    $promptHash{$1}{$langVers} = $2;
                    my @prompts = split(/([MP]\d{1,})/, $2);
                    foreach my $prompt (@prompts)
                    {
                        print STDERR "***$prompt\n";
                        $allPrompts{$langVers}{$prompt} = $langVers;
                    }
                }
                else
                {
                    print STDERR "MISSING:  $line\n";
                }
            }
        }
    }
}

sub printPrompts
{    
    @langs = sort(@langs);
    foreach my $lang (@langs)
    {
        print "\t$lang";
    }
    print "\n";
    foreach my $promptNameKey (sort keys %promptHash)
    {
        print "$promptNameKey";
        foreach my $langVersKey (@langs)
        {
            if (exists $promptHash{$promptNameKey}{$langVersKey})
            {
                print "\t$promptHash{$promptNameKey}{$langVersKey}";
            }
            else
            {
                print "\tUNDEFINED";
                print STDERR "Cannot print element for $promptNameKey, $langVersKey.\n";
            }
        }
        print "\n";
    }
    
    print "\n\n\n";
    foreach my $lang (@langs)
    {
        print "$lang\n";
        foreach my $prompt (sort keys $allPrompts{$lang})
        {
            if($getVerbiage)
            {
                printf("%-10s-> %s\n", $prompt, getVerbiage($prompt));
            }
            else
            {
                print "$prompt\n";
            }
        }
        print "\n\n";
    }
}

sub getVerbiage
{
    my $prompt = $_[0];
    my ($url, $content, $returnString);
    if($prompt =~ /M?(\d{4,6})/)
	{
		$url = 'http://nor2k3pdms1:8080/pdms/text?prompt=M'.$1;
		$content = get($url);
		if(defined $content && $content ne "null")
		{
		    chomp($content);
			return $content;
		}
		else
		{
			$url = 'http://nor2k3pdms2:8080/pdms/text?prompt=M'.$1;
			$content = get($url);
			if(defined $content)
			{
	    	    chomp($content);
    			return $content;
			}
			else
			{
				return "UNKNOWN";
			}
		}
		$content = "";
	}
}

