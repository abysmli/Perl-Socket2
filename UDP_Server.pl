#!/usr/bin/perl -w

###############################################################################################################
#                                                                                                             #
#                                       File:     UDP_Server.pl                                               #
#                                       Autor:    Li, Yuan                                                    #
#                                       Version:  beta 2                                                      #
#                                       Date:     12.12.2012                                                  #
#                                                                                                             #
###############################################################################################################

use IO::Socket::INET;
use strict;
use Time::HiRes qw(gettimeofday);

########################################---Main-Programm---####################################################

my $iHostPort=$ARGV[0];
my $CSocket_Packet_Receiver = new IO::Socket::INET(
	LocalPort=>$iHostPort,
	Timeout=>1,
	Proto=>'UDP'
);
die "Konnte keine Verbindung herstellen\n" unless $CSocket_Packet_Receiver;
print "UDP Server bereit und wartet auf dem Port $iHostPort\n\n";
my $bFlag=1;
my @Packet_Final;
my $Packet_Size=0;
my ($Timer1, $Timer2);
my $bFirstTimeFlag=1;
my $iSequenzNumberBefore=0;
while(1)
{
	my $sReceived_Packet;
	$CSocket_Packet_Receiver->recv($sReceived_Packet,1024);
	
	if ($sReceived_Packet eq '')
	{
		my ($Packet_End_sec, $Packet_End_usec) = gettimeofday();
		$Timer2=$Packet_End_sec.".".&BitAlignment(6, $Packet_End_usec);
		for (my $i=0;$i<=100;$i++)
		{
			$CSocket_Packet_Receiver->send(1);
		}
		last;
	}
	
	my $iSequenzNumber=substr($sReceived_Packet,0,5)+0;
	if ($iSequenzNumber != $iSequenzNumberBefore)
	{
		$bFirstTimeFlag=1;
		$iSequenzNumberBefore=$iSequenzNumber;
	}
	else
	{
		$bFirstTimeFlag=0;
	}
	if ($bFirstTimeFlag)
	{
		$Packet_Size+=length($sReceived_Packet);
	}
	my $sReceived_Packet_changed=substr($sReceived_Packet,5,1019);

	if ($iSequenzNumber==1&&$bFirstTimeFlag)
	{
		my ($Packet_Begin_sec, $Packet_Begin_usec) = gettimeofday();
		$Timer1 = $Packet_Begin_sec.".".&BitAlignment(6, $Packet_Begin_usec);
	}

	$Packet_Final[$iSequenzNumber]=$sReceived_Packet_changed;
	$CSocket_Packet_Receiver->send($iSequenzNumber);
}
&Display_Packet;


########################################---Sub-Programms---####################################################

sub Display_Packet
{
	for (my $i=1;$i<=$#Packet_Final;$i++)
	{
		print $Packet_Final[$i];
	}
	my $sPeer_Address = $CSocket_Packet_Receiver->peerhost();
	my $sPeer_Port = $CSocket_Packet_Receiver->peerport();
	print "\nPacket from [$sPeer_Address] : $sPeer_Port\n";
	print "Packet Size : $Packet_Size Byte\n";
	my $Timer = $Timer2 - $Timer1;
	print "Time difference : $Timer s\n";
	my $fDatarate=$Packet_Size/1000/$Timer;
	print "Datarat : $fDatarate kByte/s\n";
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
