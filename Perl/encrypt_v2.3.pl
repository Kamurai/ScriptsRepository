#!/usr/local/bin/perl
#encrypt/deEncrypt/MOD10 accounts in file provided as argument

use warnings;
use strict;

use File::Basename;

use constant SRCNDX => [ 14,13,12,11,10,9,8,15,1,3,5,4,7,2,0,6 ];
use constant CALCTYPE => [ 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 ];
use constant DESTDIFF => [ 7, 6, 5, 4, 3, 2, 9, 0, 3, 7, 6, 8, 2, 5, 1, 4];

use constant {
	ENCRYPT => 'Encrypt',
	DeENCRYPT => 'DeEncrypt',
	MAKEMEMOD10 => 'MakeMeMod10',
};
use constant {
	SCREEN => 'STDOUT',
	FILE => 'File',
};

my ($mode, $file, $tArrayNdx, $format, $delimited, $delimiter, $fileOut, $modeStr, @workAccounts, $outString);
my ($tempStr1, $tempStr2);


if($#ARGV < 0)
{
	print "Incorrect usage:  \n";
	exit(2);
}

$format = SCREEN;
$fileOut = "";
$outString = "";

for($tArrayNdx = 0; $tArrayNdx <= $#ARGV; $tArrayNdx += 1)
{
	if($ARGV[$tArrayNdx] eq "-d")
	{
		$mode = DeENCRYPT;
		$modeStr = "deEn";
	}
	elsif( ($ARGV[$tArrayNdx] eq "-e" || $ARGV[$tArrayNdx] =~ /encrypt/i)  && (!-e $ARGV[$tArrayNdx]))
	{
		$mode = ENCRYPT;
		$modeStr = "enc";
	}
	elsif( $ARGV[$tArrayNdx] eq "-m" || $ARGV[$tArrayNdx] eq "-M" || $ARGV[$tArrayNdx] =~ /.*makememod10.*/i)
	{
		$mode = MAKEMEMOD10;
		$modeStr = "mod10";
	}
	elsif( $ARGV[$tArrayNdx] eq "-del" )
	{
		$delimited = 1;
		if( ($tArrayNdx + 1) <= $#ARGV && $ARGV[$tArrayNdx+1] =~ /(?:-d|-e|-f|-m|-del|-p|-f)/i )
		{
			$delimiter = ",";
		}
		elsif( ($tArrayNdx + 1) >= $#ARGV)
		{
			$delimiter = ",";
		}
		else
		{
			$delimiter = $ARGV[$tArrayNdx+1];
			$tArrayNdx++;
		}
	}
	elsif( $ARGV[$tArrayNdx] =~ /-p/i )
	{
		$format = SCREEN;
	}
	elsif( $ARGV[$tArrayNdx] =~ /-f/i )
	{
		$format = FILE;
		if( ($tArrayNdx + 1) <= $#ARGV && $ARGV[$tArrayNdx+1] =~ /(?:-d|-e|-f|-m|-del|-p|-f)/i )
		{
		}
		elsif(($tArrayNdx + 1) <= $#ARGV)
		{
			$fileOut = $ARGV[$tArrayNdx+1];
		}
		else
		{
			print "HERE";
		}
	}
}
$file = $ARGV[0];
if(-e $file)
{
	$file = $ARGV[0];
	open(DATAIN, $file);
	@workAccounts = <DATAIN>;
	close(DATAIN);
	if($format eq SCREEN)
	{
	}
	else
	{
		my($filename, $directories) = fileparse($file);
		if(!$fileOut)
		{
			$fileOut = $directories;
			$tArrayNdx = rindex($filename, '.');
			if($tArrayNdx == -1)
			{
				$fileOut = $fileOut.$filename."_".$modeStr;
			}
			else
			{
				$tempStr1 = substr($filename, 0, $tArrayNdx);
				$tempStr2 = substr($filename, $tArrayNdx + 1);
				$fileOut = $fileOut."$tempStr1.$modeStr.$tempStr2";
			}
		}
		print "$fileOut\n\n";
	}
}
else
{
	print "ACCTS:  $ARGV[0]\n";
	if($delimited)
	{
		print "Delimiter $delimiter\n";
		@workAccounts = split(/$delimiter/, $ARGV[0]);
	}
	if($format eq SCREEN)
	{
	}
	else
	{
		if(!$fileOut)
		{
			$format = SCREEN;
		}
	}
}

if($mode eq ENCRYPT)
{
	$outString = encrypt(@workAccounts);
}
elsif($mode eq DeENCRYPT)
{
	$outString = deEncrypt(@workAccounts);
}
elsif($mode eq MAKEMEMOD10)
{
	$outString = makeMeMod10(@workAccounts);
}
else
{
	print "Unknown mode of operation, must be -d for deEncrypt, -e for encrypt, or -m for makeMeMod10.\n";
	exit 0;
}
printOutput($format, $outString, $fileOut);
exit(0);

sub printOutput
{
	my ($format, $output, $outFile);
	$format = $_[0];
	$output = $_[1];
	$outFile = $_[2];

	if($format eq SCREEN)
	{
		print "$output\n";
	}
	elsif($format eq FILE)
	{
		if(!$outFile)
		{
			print "$output\n";
		}
		else
		{
			open(DATAOUT, ">$outFile");
			print DATAOUT "$output\n";
			close(DATAOUT);
		}
	}
}

sub encrypt
{
	my (@accounts, $workAccount, $returnString, $tempString);
	@accounts = @_;
	$returnString = "ACCT  TO ENCRYPT\tMAKEMEMOD10 ACCT\tENCRYPTED ACCT #\n";
	foreach $workAccount (@accounts)
	{
		if($workAccount =~ /.*(\d{16}).*/)
		{
			$tempString = accountMod10($1);

			$returnString = $returnString."\n$1\t".$tempString."\t";
			$tempString = manipAccount($tempString, 1);
			if($tempString =~ /(\d{16})/)
			{
				$returnString = $returnString."$1";
			}
			else
			{
				$returnString = $returnString."--> Failed to encrypt.";
			}
		}
	}
	return $returnString;
}

sub deEncrypt
{
	my (@accounts, $workAccount, $returnString, $tempString, $preAcctInfo, $postAcctInfo);
	@accounts = @_;
	$returnString = "ACCOUNT TO DeENC\tDeENCRYPT ACCT #\tMAKEMEMOD10 ACCT #\n";
	foreach $workAccount (@accounts)
	{
	    chomp ($workAccount);
		if($workAccount =~ /(.*)(\d{16})(.*)/)
		{
			$preAcctInfo = $1;
			$postAcctInfo = $3;			
			$tempString = manipAccount($2, -1);
			$returnString = $returnString."\n$2\t".$tempString."\t";
			$tempString = accountMod10($tempString);
			if($tempString =~ /(\d{4})(\d{4})(\d{4})(\d{4})/)
			{
				$returnString = $returnString."$1 $2 $3 $4";
			}
			else
			{
				$returnString = $returnString."--> Failed to deEncrypt.";
			}			
			$preAcctInfo =~ s/\t+/ /;
			$postAcctInfo =~ s/\t+/ /;
			$returnString = $returnString.$preAcctInfo." === ".$postAcctInfo;
		}
	}
	return $returnString;
}

sub makeMeMod10
{
	my (@accounts, $workAccount, $returnString, $tempString);
	@accounts = @_;
	$returnString = "MOD10 ACCOUNT IN\tMOD10 ACCOUNT OUT\n";
	foreach $workAccount (@accounts)
	{
		if($workAccount =~ /.*(\d{16}).*/)
		{
			$returnString = $returnString."\n$1\t";
			$tempString = accountMod10($1);
			if($tempString =~ /(\d{4})(\d{4})(\d{4})(\d{4})/)
			{
				$returnString = $returnString."$1 $2 $3 $4";
			}
			else
			{
				$returnString = $returnString."--> Failed to makeMeMod10.";
			}
		}
	}
	return $returnString;
}

sub manipAccount
{
	my ($acctToEnc, @acctInts, $srcLoc, $destDiff, $destLoc, $calc, $currValue, $arrayNdx, $returnVal, $sign, $numIn, @acctNum);
	$acctToEnc = $_[0];
	$sign = int($_[1]);  #1 for encrypt -1 for deEncrypt
	@acctInts = split(//, $acctToEnc);
	for($arrayNdx = 0; $arrayNdx <= $#acctInts; $arrayNdx++)
	{
		$calc = CALCTYPE->[$arrayNdx];
		
		if ($sign == 1)
		{
			$destLoc = $arrayNdx;
			$numIn = int($acctInts[SRCNDX->[$arrayNdx]]);
			$destDiff = DESTDIFF->[$arrayNdx];
		}
		else
		{
			$destLoc = SRCNDX->[$arrayNdx];
			$numIn = int($acctInts[$arrayNdx]);
			$destDiff = DESTDIFF->[$arrayNdx];
		}
		
		if($calc == 1)
		{
			$currValue = 9 - $numIn;
		}
		else
		{
			$currValue = int($numIn) + int($destDiff * $sign);
			if($currValue > 9)
			{
				$currValue = $currValue - 10;
			}
			if ($currValue < 0) 
			{
				$currValue = $currValue + 10;
			}
		}
		$acctNum[$destLoc] = "$currValue";
	}
	$returnVal = formatString(@acctNum);
}

sub accountMod10
{
	my ($acctForMod10, $returnVal, $sum, @acctByDigit, $len, $arrayNdx, $tempVal);
	$acctForMod10 = $_[0];
	@acctByDigit = split(//, $acctForMod10);
	$len = length($acctForMod10);
	for($arrayNdx = 1; $arrayNdx < $len; $arrayNdx++)
	{
		$tempVal = int($acctByDigit[($len - 1) - $arrayNdx]);		
		if( $arrayNdx % 2 )
		{
			$tempVal = ($tempVal * 2);
			if ($tempVal > 9)
			{
				$sum += int(($tempVal % 10) + 1);
			}
			else
			{
				$sum += int($tempVal);
			}
		}
		else
		{
			$sum += int($tempVal);
		}
		
	}
	$sum = int(10 - ($sum % 10));
	if( $sum == 10)
	{
		$sum = int(0);
	}
	$acctByDigit[$len - 1] = chr($sum + 48);
	$returnVal = formatString(@acctByDigit);
}


sub formatString
{
	my ($returnVal, @acctToFormat, $arrayNdx);
	@acctToFormat = @_;
	for($arrayNdx = 0; $arrayNdx < 16; $arrayNdx++)
	{
		$returnVal = $returnVal."$acctToFormat[$arrayNdx]"
	}
	return $returnVal;
}