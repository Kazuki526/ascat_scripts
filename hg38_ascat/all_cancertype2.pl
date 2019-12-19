#!/usr/bin/perl
use strict;
use warnings;

my $ascat_dir="/Volumes/areca42TB/tcga/CNA";
my @cancertype = qw(lihc meso paad pcpg sarc skcm stad tgct thym ucs uvm blca cesc chol dlbc esca laml);
foreach my $cancertype (@cancertype){
		print "#################################################### $cancertype ####################################################\n";
		mkdir "$ascat_dir/$cancertype";
		my $dir = "$ascat_dir/$cancertype/cel";
		mkdir "$dir";
		chdir $dir;
		system("perl $ENV{HOME}/git/ascat_script/hg38_ascat/main2.pl 2>&1|tee -a out38.log");
		if(`grep \"perfectly done ascat\" out.log` !~ /./){die "######### stop at $cancertype ##########\n";}
}
