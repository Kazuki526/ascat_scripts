#!/usr/bin/perl
use warnings;
use strict;

############################################################################
## exanmple script
## perl by_project_main.pl 2>&1|tee out38.log
###########################################################################

my ($normjson,$tumorjson,$normmanifest,$tumormanifest,$token);
my $pwd=`pwd`;chomp $pwd;
print "doing on $pwd\n";
my $ct; #cancer type(project name)
if($pwd=~/\/(\w+)\/cel$/){$ct=$1;}else{die "ERROR::work on wrong dir?\n";}
my $uc_ct = uc $ct;

$normjson= "$ct"."_cna_norm.json";
$tumorjson="$ct"."_cna_tumor.json";
#system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_norm.json|sed s/cancertype/$uc_ct/ >$normjson");
#system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_tumor.json|sed s/cancertype/$uc_ct/ >$tumorjson");
#if($ct eq "laml"){system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_tumor.json |sed s/cancertype/$uc_ct/ |sed s/Primary\\ Tumor/Primary\\ Blood\\ Derived\\ Cancer\\ -\\ Peripheral\\ Blood/ >$tumorjson");}

$normmanifest= "gdc_manifest.$ct". "_norm_cel.tsv";
$tumormanifest="gdc_manifest.$ct". "_tumor_cel.tsv";
my $tokenfile=`ls ~/git/innanlab/gdc|grep gdc-user-token`;
if($tokenfile!~/./){die "!!ERROR!!: not exist token file\n";}
chomp ($normjson,$tumorjson,$normmanifest,$tumormanifest,$tokenfile);

$token="$ENV{HOME}/git/innanlab/gdc/$tokenfile";
-e $token or die "ERROR::not exist $token file\n";
print "check manifest & jsonfile & token files\n";
if(`ls|grep out38\.log` !~ /./){die "not put out log to file\n redo by writing log to out38.log\n";}

#system("curl --request POST --header \"Content-Type: application/json\" --data \@$tumorjson \'https://api.gdc.cancer.gov/legacy/files\' > response_tumorcel.tsv");
#system("curl --request POST --header \"Content-Type: application/json\" --data \@$normjson \'https://api.gdc.cancer.gov/legacy/files\' > response_normcel.tsv");
my %response=();
open(NORM,"response_normcel.tsv") or die "ERROR normal response is not available\n";
open(TUMOR,"response_tumorcel.tsv") or die "ERROR tumor response is not availabel\n";;
open(FILE,">file_check.txt");
my $dummy=<NORM>;chomp $dummy;
my %col = &header2hash($dummy);
if( (!defined $col{'cases.0.submitter_id'})||
	(!defined $col{'cases.0.samples.0.sample_type'})||
	(!defined $col{'file_name'})||
	(!defined $col{'file_id'})||
	(!defined $col{'file_size'})||
	(!defined $col{'md5sum'})||
	(!defined $col{'state'})){die "ERROR::there are some problem on response file. colum name chnaged?\n";}
while(<NORM>){
		chomp;
		my @line=split(/\t/,);
		if(exists $response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{file}){
				print FILE "$line[$col{'cases.0.submitter_id'}] heve 2 or more tumor files\t$line[$col{'cases.0.samples.0.sample_type'}], ";
				print FILE "$response{$line[$col{'cases.0.submitter_id'}]}{norm}{sampletype}\n";
				if($line[$col{'cases.0.samples.0.sample_type'}] eq "Blood Derived Normal"){
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'file'}=$line[$col{'file_name'}];
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'sampletype'}=$line[$col{'cases.0.samples.0.sample_type'}];
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'uuid'}=$line[$col{'file_id'}];
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'md5'}=$line[$col{'md5sum'}];
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'size'}=$line[$col{'file_size'}];
						$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'state'}=$line[$col{'state'}];
				}
		}else{
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'file'}=$line[$col{'file_name'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'sampletype'}=$line[$col{'cases.0.samples.0.sample_type'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'uuid'}=$line[$col{'file_id'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'md5'}=$line[$col{'md5sum'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'size'}=$line[$col{'file_size'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'norm'}{'state'}=$line[$col{'state'}];
		}
}
close NORM;
$dummy=<TUMOR>;chomp $dummy;
%col = &header2hash($dummy);
if( (!defined $col{'cases.0.submitter_id'})||
	(!defined $col{'cases.0.samples.0.sample_type'})||
	(!defined $col{'file_name'})||
	(!defined $col{'file_id'})||
	(!defined $col{'file_size'})||
	(!defined $col{'md5sum'})||
	(!defined $col{'state'})){die "ERROR::there are some problem on response file. colum name chnaged?\n";}
while(<TUMOR>){
		chomp;
		my @line =split(/\t/,);
		if(exists $response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{file}){
				print FILE "$line[$col{'cases.0.submitter_id'}] heve 2 or more tumor files\t$line[$col{'cases.0.samples.0.sample_type'}], ";
				print FILE "$response{$line[$col{'cases.0.submitter_id'}]}{tumor}{sampletype}\n";
		}else{
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'file'}=$line[$col{'file_name'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'sampletype'}=$line[$col{'cases.0.samples.0.sample_type'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'uuid'}=$line[$col{'file_id'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'md5'}=$line[$col{'md5sum'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'size'}=$line[$col{'file_size'}];
				$response{$line[$col{'cases.0.submitter_id'}]}{'tumor'}{'state'}=$line[$col{'state'}];
		}
}
close TUMOR;

my $pwdn=`pwd`;chomp $pwdn;
if($pwd ne $pwdn){die "ERROR stopped at line 148 by_project_main.pl\n";}

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
		print "doing $subdir ascat\n";
		system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/2sample_ascat.R $subdir $pwd $sex >/dev/null 2>&1");
		if(-e ("ascat/$subdir/$subdir"."_ascat.tsv")){
				unlink "ascat/$subdir/normal.LogR.txt";
				unlink "ascat/$subdir/normal.BAF.txt";
				unlink "ascat/$subdir/tumor.LogR.txt";
				unlink "ascat/$subdir/tumor.BAF.txt";
				unlink "ascat/$subdir/$subdir.BAF.PDFed.txt";
				unlink "ascat/$subdir/$subdir.LogR.PDFed.txt";
		}else{print "ERROR::$subdir cannot run ASCAT\n";}
#fork end
		$pm->finish;
}
$pm->wait_all_children;

system("perl ~/git/ascat_scripts/hg38_ascat/annotate_ascat110.pl");

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
