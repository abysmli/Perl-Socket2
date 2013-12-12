#!/usr/bin/perl -w

###############################################################################################################
#                                                                                                             #
#                                       File:     UDP_Client.pl                                               #
#                                       Autor:    Li, Yuan                                                    #
#                                       Version:  beta 2                                                      #
#                                       Date:     12.12.2012                                                  #
#                                                                                                             #
###############################################################################################################

use IO::Socket::INET;
use strict;
use Time::HiRes qw(gettimeofday);

########################################---Main-Programm---####################################################

my $iDest_IP_Addr = $ARGV[0];
my $iDest_Port = $ARGV[1];
my $Packet_Size=0;
my $CSocket_Packet_Sender = new IO::Socket::INET(
	PeerAddr=>$iDest_IP_Addr,
	PeerPort=>$iDest_Port,
	Timeout=>1,
	Proto=>'UDP'
);
die "Konnte keinen Socket_Packet_Sender herstellen\n" unless $CSocket_Packet_Sender;
my @sPacket = &Packet_Creater;
my $Timer = &Send_Packet;
my $fDatarate=$Packet_Size/1000/$Timer;
print "\nPacket to [$iDest_IP_Addr] : $iDest_Port\n";
print "Packet Size : $Packet_Size Byte\n";
print "Time difference : $Timer s\n";
print "Datarat : $fDatarate kByte/s\n";


########################################---Sub-Programms---####################################################
sub Packet_Creater
{
	my @sPacket;
	my $sFull_Message;
	while(defined(my $sGet_Message = <STDIN>))
	{
		$sFull_Message=$sFull_Message.$sGet_Message;
	}
	for(my $i=1;$i<=(int(length($sFull_Message)/1000)+1);$i++)
	{
		$sPacket[$i] = &BitAlignment(5,$i).substr($sFull_Message,($i-1)*1000,1000);
	}
	return @sPacket;
}

sub Send_Packet
{
	my ($Timer1, $Timer2);
	for(my $i=1;$i<=$#sPacket;$i++)
	{
		my $bResponse=-1;
		my $iRetryTimes=0;
		while($bResponse)
		{
			$iRetryTimes++;
			eval 
			{ 
				local $SIG{ALRM} = sub { die 'Timed Out'; }; 
    			alarm 1; 
				$CSocket_Packet_Sender->send($sPacket[$i]);
				$CSocket_Packet_Sender->recv($bResponse,5);
				alarm 0; 
			}; 
			if ($@) 
			{
				print "In Retry Loop!   Packet Number: $i | Retry Times: $iRetryTimes\n";
			}
			if (!defined($bResponse)||($bResponse eq ''))
			{
				$bResponse=-1;
			}
			if ($bResponse==$i)
			{
				if($i==1)
				{
					my ($Packet_Begin_sec, $Packet_Begin_usec) = gettimeofday();
					$Timer1 = $Packet_Begin_sec.".".&BitAlignment(6, $Packet_Begin_usec);
				}
				$iRetryTimes--;
				print "Get Out of Loop! Packet Number: $i | Retry Times: $iRetryTimes\n";
				$bResponse=0;
			}
			else
			{
				$bResponse=1;
			}
		}
		$Packet_Size+=length($sPacket[$i]);
	}
	&Send_End_Flag;
	my ($Packet_End_sec, $Packet_End_usec) = gettimeofday();
	$Timer2=$Packet_End_sec.".".&BitAlignment(6, $Packet_End_usec);
	return ($Timer2-$Timer1);
}

sub BitAlignment
{
	my ($iBitLength, $Number)=@_;
	my $iLength=length($Number);
	for (my $i=0;$i<$iBitLength-$iLength;$i++)
	{
		$Number="0".$Number;
	}
	return $Number;
}

sub Send_End_Flag
{
	print "Send End Flag!\n";
	my $bResponse=0;
	my $iRetryTimes=0;
	while(1)
	{
		$iRetryTimes++;
		eval 
		{ 
   			local $SIG{ALRM} = sub { die 'Timed Out'; }; 
    		alarm 1; 
      		$CSocket_Packet_Sender->send("");
			$CSocket_Packet_Sender->recv($bResponse,1);
    		alarm 0; 
		}; 
		if ($@) 
		{
			print "In Retry Loop!   End Flag | Retry Times: $iRetryTimes\n";
		}
		if (!defined($bResponse)||($bResponse eq ''))
		{
			$bResponse=-1;
		}
		if ($bResponse==1)
		{
			$iRetryTimes--;
			print "Get Out of Loop! End Flag | Retry Times: $iRetryTimes\n";
			print "Packet sent succesful!\n";
			last;
		}
	}
	return $bResponse;
}