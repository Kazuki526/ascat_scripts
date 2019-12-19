#!/usr/bin/perl
use warnings;
use strict;

############################################################################
## exanmple script
## perl by_project_main.pl 2>&1|tee out.log
###########################################################################

my ($normjson,$tumorjson,$normmanifest,$tumormanifest,$token);
my $pwd=`pwd`;chomp $pwd;
print "doing on $pwd\n";
my $ct; #cancer type(project name)
if($pwd=~/\/(\w+)\/cel$/){$ct=$1;}else{die "ERROR::work on wrong dir?\n";}
my $uc_ct = uc $ct;

$normjson= "$ct"."_cna_norm.json";
$tumorjson="$ct"."_cna_tumor.json";
system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_norm.json|sed s/cancertype/$uc_ct/ >$normjson");
system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_tumor.json|sed s/cancertype/$uc_ct/ >$tumorjson");
if($ct eq "laml"){system("cat ~/git/ascat_scripts/hg19_ascat/project_cna_tumor.json |sed s/cancertype/$uc_ct/ |sed s/Primary\\ Tumor/Primary\\ Blood\\ Derived\\ Cancer\\ -\\ Peripheral\\ Blood/ >$tumorjson");}

$normmanifest= "gdc_manifest.$ct". "_norm_cel.tsv";
$tumormanifest="gdc_manifest.$ct". "_tumor_cel.tsv";
my $tokenfile=`ls ~/git/innanlab/gdc|grep gdc-user-token`;
if($tokenfile!~/./){die "!!ERROR!!: not exist token file\n";}
chomp ($normjson,$tumorjson,$normmanifest,$tumormanifest,$tokenfile);

$token="$ENV{HOME}/git/innanlab/gdc/$tokenfile";
-e $token or die "ERROR::not exist $token file\n";
print "check manifest & jsonfile & token files\n";
if(`ls|grep out\.log` !~ /./){die "not put out log to file\n redo by writing log to out.log\n";}

system("curl --request POST --header \"Content-Type: application/json\" --data \@$tumorjson \'https://api.gdc.cancer.gov/legacy/files\' > response_tumorcel.tsv");
system("curl --request POST --header \"Content-Type: application/json\" --data \@$normjson \'https://api.gdc.cancer.gov/legacy/files\' > response_normcel.tsv");
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

open(NCL,">norm_cel_list.txt");
open(TCL,">tumor_cel_list.txt");
print NCL "cel_files\tfilename\tpatient\n";
print TCL "cel_files\tfilename\tpatient\n";

open(NMAN,">$normmanifest");
print NMAN "id\tfilename\tmd5\tsize\tstate\n";
open(TMAN,">$tumormanifest");
print TMAN "id\tfilename\tmd5\tsize\tstate\n";

#making output dir
mkdir './ascat' or die"cant mkdir ascat";
my($norm,$tumor,$normn,$tumorn)=("","",0,0);
foreach my $patient (keys %response){
		unless(exists $response{$patient}{'norm'}{file}){
				$norm.="$patient\t";
				$normn++;
				next;
		}
		unless(exists $response{$patient}{'tumor'}{file}){
				$tumor.="$patient\t";
				$tumorn++;
				next;
		}
#making output subdir
		mkdir("./ascat/$patient") or die "can't make dir $patient\n" ;
		print NCL "norm/$response{$patient}{norm}{uuid}/$response{$patient}{norm}{file}\t$response{$patient}{norm}{file}\t$patient\n";
		print TCL "tumor/$response{$patient}{tumor}{uuid}/$response{$patient}{tumor}{file}\t$response{$patient}{tumor}{file}\t$patient\n";
		print NMAN "$response{$patient}{norm}{uuid}\t$response{$patient}{norm}{file}\t$response{$patient}{norm}{md5}\t";
		print NMAN "$response{$patient}{norm}{size}\t$response{$patient}{norm}{state}\n";
		print TMAN "$response{$patient}{tumor}{uuid}\t$response{$patient}{tumor}{file}\t$response{$patient}{tumor}{md5}\t";
		print TMAN "$response{$patient}{tumor}{size}\t$response{$patient}{tumor}{state}\n";
}
print FILE "\nThere is no norm file of $normn patient\n$norm\n\nThere is no tumor file of $tumorn patient\n$tumor\n";
close TCL;
close NCL;
close FILE;
close NMAN;
close TMAN;

if(($normmanifest!~/./)||($tumormanifest!~/./)){die "!!ERROR!!: not exist manifest file\n";}
mkdir './norm';
chdir './norm';
system("~/gdc-client download -m $pwd/$normmanifest -t $token");
chdir '..';
if(`grep ERROR out.log|grep 31m` =~ /./){die "there are some ERROR by download cel files\n check out.log and redownload cel files\n";}
mkdir 'tumor';
chdir 'tumor';
system("~/gdc-client download -m $pwd/$tumormanifest -t $token");
chdir '../';
if(`grep ERROR out.log|grep 31m` =~ /./){die "there are some ERROR by download cel files\n check out.log and redownload cel files\n";}

my $pwdn=`pwd`;chomp $pwdn;
if($pwd ne $pwdn){die "ERROR stopped at line 148 by_project_main.pl\n";}

system('sh ~/git/ascat_scripts/hg19_ascat/make_norm_gw6_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/split_lrr_baf.R norm_lrr_baf.txt norm_cel_list.txt $pwd");

system('sh ~/git/ascat_scripts/hg19_ascat/make_tumor_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_scripts/hg19_ascat/split_lrr_baf.R tumor_lrr_baf.txt tumor_cel_list.txt $pwd");

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

system("perl ~/git/ascat_scripts/hg19_ascat/annotate_ascat110.pl");

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
