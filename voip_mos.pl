#!/usr/bin/perl -w

use strict;
use warnings;

my $ip = $ARGV[0];
my @rt = (0,0,0,0,0);
my $mean = 0.0;
my $jitter;
my $codec_delay = 10.0;
my @avg_late;
my $avg_latency;
my $r_value;
my $ret_val;
my @ploss;
my $packet_loss;
my $late;
my $min;
my $max;


for (my $n = 0; $n < 5; $n++) {
    $rt[$n] = `ping -nc 1 $ip | sed -n 2p | cut -d ' ' -f 7 | cut -d '=' -f 2`;
    $avg_late[$n] = `ping -c 1 $ip | tail -1| cut -d '/' -f 5`;
    $ploss[$n] =  `ping -nc 1 $ip | sed -n 5p | cut -d ',' -f 3 | cut -d '%' -f 1`;
    $mean += $rt[$n];
    $avg_latency += $avg_late[$n];
    $packet_loss += $ploss[$n];
}

$avg_latency /= 5;
$packet_loss /= 5;
$mean /= 5;

for (my $n = 0; $n < 5; $n++) {
    $jitter += ($rt[$n] - $mean) ** 2;
}

print $ip;
$jitter /= 5;
$jitter = sprintf "%.3f",$jitter;
# print "\n Avg Jitter: $jitter \n \n";
# print "Avg Latency: $avg_latency \n \n";
# print "Packet Loss: $packet_loss% \n \n";

# Calculate MOS 

    # Take the average latency, add jitter, but double the impact to latency
    # then add 10 for protocol latancies
    my $effective_latency = ( $avg_latency + $jitter * 2 + 10 );
 
    # Implement a basic curve - deduct 4 for the r_value at 160ms of latency
    # (round trip). Anything over that gets a much more agressive deduction
    if ($effective_latency < 160) {
        $r_value = 93.2 - ($effective_latency / 40);
    }
    else {
        $r_value = 93.2 - ($effective_latency - 120) / 10;
    }
 
    # Now, let's deduct 2.5 r_value per percentage of packet_loss
    $r_value = $r_value - ($packet_loss * 2.5);
 
    # Convert the r_value into an MOS value. (this is a known formula)
    $ret_val = 1 + 
        (0.035) *
        $r_value +
        (0.000007) *
        $r_value *
        ($r_value - 60) *
        (100 - $r_value);
    $ret_val = sprintf( "%.3f", $ret_val);

    # print "Mos: $ret_val \n \n";


if ($ret_val < 3.1)
{
    $max=$ret_val;
}
elsif ($ret_val > 3.1)
{
    $min = 0;
}
else
{
print "Error \n"; 
}
# print $max;

print "<module>\n";
print "<name><![CDATA[Voip_Mos]]></name>\n";
print "<type><![CDATA[generic_data]]></type>\n";
print "<description><![CDATA[Mean Opinion Score, is a measure of voice quality]]></description>\n";
print "<min_critical><![CDATA[".$min."]]></min_critical>\n";
print "<max_critical><![CDATA[$max]]></max_critical>\n";
print "<data><![CDATA[".$ret_val."]]></data>\n";
print "</module>\n";
