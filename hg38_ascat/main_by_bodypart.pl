#!/usr/bin/perl
use warnings;
use strict;

############################################################################
## exanmple script
## perl main.pl 2>&1|tee out38.log
###########################################################################

my ($normjson,$tumorjson,$normmanifest,$tumormanifest,$token);
my $pwd=`pwd`;chomp $pwd;
print "doing on $pwd\n";
$normjson= `ls|grep cna_norm.json`;
$tumorjson=`ls|grep cna_tumor.json`;
#if(($normjson!~/./)||($tumorjson!~/./)){die "!!ERROR!!: not exist json file\n";}
$normmanifest= `ls|grep gdc_manifest|grep norm`;
$tumormanifest=`ls|grep gdc_manifest|grep tumor`;
#if(($normmanifest!~/./)||($tumormanifest!~/./)){die "!!ERROR!!: not exist manifest file\n";}

my $tokenfile=`ls ~/git/innanlab/gdc|grep gdc-user-token`;
#if($tokenfile!~/./){die "!!ERROR!!: not exist token file\n";}
chomp ($normjson,$tumorjson,$normmanifest,$tumormanifest,$tokenfile);

#$token="~/git/gdc_il/$tokenfile";
print "check manifest & jsonfile & token files\n";
#if(`ls|grep out38\.log` !~ /./){die "not put out log to file\n redo by writing log to out38.log\n";}

my $pwdn=`pwd`;chomp $pwdn;
if($pwd ne $pwdn){die "ERROR stopped at line 23 main.pl\n";}

#system("curl --request POST --header \"Content-Type: application/json\" --data \@$tumorjson \'https://gdc-api.nci.nih.gov/legacy/files\' > response_tumorcel.tsv");
#system("curl --request POST --header \"Content-Type: application/json\" --data \@$normjson \'https://gdc-api.nci.nih.gov/legacy/files\' > response_normcel.tsv");
my %response=();
open(NORM,"response_normcel.tsv") or die "ERROR normal response is not available\n";
open(TUMOR,"response_tumorcel.tsv") or die "ERROR tumor response is not availabel\n";;
open(FILE,">file_check.txt");
my $dummy=<NORM>;chomp $dummy;
my %col = &header2hash($dummy);
if( (!defined $col{'cases_0_submitter_id'})||
	(!defined $col{'cases_0_samples_0_sample_type'})||
	(!defined $col{'file_name'})||
	(!defined $col{'file_id'})){die "ERROR::there are some problem on response file. colum name chnaged?\n";}
while(<NORM>){
		chomp;
		my @line=split(/\t/,);
		if(exists $response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{file}){
				print FILE "$line[$col{'cases_0_submitter_id'}] heve 2 or more tumor files\t$line[$col{'cases_0_samples_0_sample_type'}], ";
				print FILE "$response{$line[$col{'cases_0_submitter_id'}]}{norm}{sampletype}\n";
				if($line[$col{'cases_0_samples_0_sample_type'}] eq "Blood Derived Normal"){
						$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'file'}=$line[$col{'file_name'}];
						$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'sampletype'}=$line[$col{'cases_0_samples_0_sample_type'}];
						$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'uuid'}=$line[$col{'file_id'}];
				}
		}else{
				$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'file'}=$line[$col{'file_name'}];
				$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'sampletype'}=$line[$col{'cases_0_samples_0_sample_type'}];
				$response{$line[$col{'cases_0_submitter_id'}]}{'norm'}{'uuid'}=$line[$col{'file_id'}];
		}
}
close NORM;
$dummy=<TUMOR>;chomp $dummy;
%col = &header2hash($dummy);
if( (!defined $col{'cases_0_submitter_id'})||
	(!defined $col{'cases_0_samples_0_sample_type'})||
	(!defined $col{'file_name'})||
	(!defined $col{'file_id'})){die "ERROR::there are some problem on response file. colum name chnaged?\n";}
while(<TUMOR>){
		chomp;
		my @line =split(/\t/,);
		if(exists $response{$line[$col{'cases_0_submitter_id'}]}{'tumor'}{file}){
				print FILE "$line[$col{'cases_0_submitter_id'}] heve 2 or more tumor files\t$line[$col{'cases_0_samples_0_sample_type'}], ";
				print FILE "$response{$line[$col{'cases_0_submitter_id'}]}{tumor}{sampletype}\n";
		}else{
				$response{$line[$col{'cases_0_submitter_id'}]}{'tumor'}{'file'}=$line[$col{'file_name'}];
				$response{$line[$col{'cases_0_submitter_id'}]}{'tumor'}{'sampletype'}=$line[$col{'cases_0_samples_0_sample_type'}];
				$response{$line[$col{'cases_0_submitter_id'}]}{'tumor'}{'uuid'}=$line[$col{'file_id'}];
		}
}
close TUMOR;


system('sh ~/git/ascat_scripts/hg38_ascat/make_norm_gw6_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/split_lrr_baf.R norm_lrr_baf_hg38.txt norm_cel_list.txt $pwd");

system('sh ~/git/ascat_scripts/hg38_ascat/make_tumor_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/split_lrr_baf.R tumor_lrr_baf_hg38.txt tumor_cel_list.txt $pwd");

my %sex=();
open(SEX,"file_sex");
while(<SEX>){
		chomp;
		my @line=split(/\t/,);
		$sex{$line[0]}=$line[1];
}
close SEX;

use Parallel::ForkManager;
my $pm=new Parallel::ForkManager(4);

my @subdir=`ls ascat`;
foreach my $subdir(@subdir){
		chomp $subdir;
		my $sex="";
		if(!$sex{$response{$subdir}{norm}{file}}){$sex="unknown";
		}else{$sex=$sex{$response{$subdir}{norm}{file}};
		}
#fork start
		$pm->start and next;
		system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/2sample_ascat.R $subdir $pwd $sex >/dev/null 2>&1");
		print "doing $subdir ascat\n";
		unlink "ascat/$subdir/normal.LogR.txt";
		unlink "ascat/$subdir/normal.BAF.txt";
		unlink "ascat/$subdir/tumor.LogR.txt";
		unlink "ascat/$subdir/tumor.BAF.txt";
		unlink "ascat/$subdir/$subdir.BAF.PDFed.txt";
		unlink "ascat/$subdir/$subdir.LogR.PDFed.txt";
#fork end
		$pm->finish;
}
$pm->wait_all_children;

system("perl ~/git/ascat_scripts/hg38_ascat/annotate_ascat110_38.pl");

print "perfectly done ascat\n";
exit;

sub header2hash ( $ ){
		my $header = $_[0];
		my @colm = split(/\t/,$header);
		my %out = ();
		for(my $i=0; $i < @colm; $i++){
				$out{$colm[$i]}=$i;
		}
		return(%out);
}
