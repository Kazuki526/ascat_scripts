#!/usr/bin/perl
use strict;
use warnings;

my $ascat_dir="/Volumes/areca42TB/tcga/CNA";
my @cancertype = qw(ov hnsc prad thca ucec);
foreach my $cancertype (@cancertype){
		print "#################################################### $cancertype ####################################################\n";
		my $dir = "$ascat_dir/$cancertype/cel";
		chdir $dir;
		system("perl $ENV{HOME}/git/ascat_scripts/hg38_ascat/main.pl 2>&1|tee -a out38.log");
		if(`grep \"perfectly done ascat\" out38.log` !~ /./){die "######### stop at $cancertype ##########\n";}
}
