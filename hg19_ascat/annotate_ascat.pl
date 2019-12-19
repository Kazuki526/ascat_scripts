#!/usr/bin/perl
use warnings;
use strict;

open(GFF,"/Users/kaz/git/driver_genes/onlytop105/top_driver105.gff");
my %gff=(); #gff{chr}{gene_symbol}{"start" or "end" or "ensg"}=star or end position or ENSG
while(<GFF>){
		if($_ =~ /chr/){next;}
		chomp;
		my @line = split(/\t/,);
		my @gene = split(/;/,$line[3]);
		$gff{$line[0]}{$gene[0]}{'start'}=$line[1];
		$gff{$line[0]}{$gene[0]}{'end'}  =$line[2];
		$gff{$line[0]}{$gene[0]}{'ensg'} =$gene[1];
}
close GFF;

open(OUT,"|gzip -c >annotate_ascat.tsv.gz");
print OUT "gene_symbol\tpatient_id\tnmajor\tnminor\tchr\tcna_start\tcna_end\tstart_rate\tend_rate\tgene_start\tgene_end\tploidy\tpurity\n";
open(ERR,">error_of_annotate_ascat.txt");
print ERR "patient_id\n";
my @subdir = `ls ascat`;
foreach my $subdir (@subdir){
		chomp $subdir;
		my $check=0;
		open(ASCAT,"ascat/$subdir/$subdir"."_ascat.tsv") or $check++;
		if($check!=0){
				print "!!!ERRORRR!!! $subdir dosent have $subdir"."_asact.tsv\n";
				print ERR "$subdir\n";
				next;
		}

		my$dev_null=<ASCAT>;
		while(<ASCAT>){
				chomp;
				my @line = split(/\t/,);
				if(!$gff{$line[1]}){next;}
				foreach my $gene_symbol (keys %{$gff{$line[1]}}){
						my $gs=$gff{$line[1]}{$gene_symbol}{start}; #gene start
								my $ge=$gff{$line[1]}{$gene_symbol}{end};   #gene end
								my $cs=$line[2]; #CNA start
								my $ce=$line[3]; #CNA end
								if    (($gs >= $cs)&&($ge <= $ce)){print OUT "$gene_symbol\t$line[0]\t$line[4]\t$line[5]\t$line[1]\t$cs\t$ce\t0\t1\t$gs\t$ge\t$line[6]\t$line[7]\n";
								}elsif(($gs >= $cs)&&($gs <= $ce)){
										my $end_rate = ($ce - $gs)/($ge - $gs);
										print OUT "$gene_symbol\t$line[0]\t$line[4]\t$line[5]\t$line[1]\t$cs\t$ce\t0\t$end_rate\t$gs\t$ge\t$line[6]\t$line[7]\n";
								}elsif(($gs <= $cs)&&($ge >= $ce)){
										my $start_rate = ($cs - $gs)/($ge - $gs);
										my $end_rate   = ($ce - $gs)/($ge - $gs);
										print OUT "$gene_symbol\t$line[0]\t$line[4]\t$line[5]\t$line[1]\t$cs\t$ce\t$start_rate\t$end_rate\t$gs\t$ge\t$line[6]\t$line[7]\n";
								}elsif(($ge >= $cs)&&($ge <= $ce)){
										my $start_rate = ($cs - $gs)/($ge - $gs);
										print OUT "$gene_symbol\t$line[0]\t$line[4]\t$line[5]\t$line[1]\t$cs\t$ce\t$start_rate\t1\t$gs\t$ge\t$line[6]\t$line[7]\n";
								}
				}
		}
		close ASCAT;
		print "done $subdir\n";
}
close OUT;
close ERR;
exit;

