#!/usr/bin/perl
use warnings;
use strict;

############################################################################
## exanmple script
## perl main.pl 2>&1|tee out.log
###########################################################################

my ($normjson,$tumorjson,$normmanifest,$tumormanifest,$token);
my $pwd=`pwd`;chomp $pwd;
print "doing on $pwd\n";
$normjson= `ls|grep cna_norm.json`;
$tumorjson=`ls|grep cna_tumor.json`;
if(($normjson!~/./)||($tumorjson!~/./)){die "!!ERROR!!: not exist json file\n";}
$normmanifest= `ls|grep gdc_manifest|grep norm`;
$tumormanifest=`ls|grep gdc_manifest|grep tumor`;
if(($normmanifest!~/./)||($tumormanifest!~/./)){die "!!ERROR!!: not exist manifest file\n";}

my $tokenfile=`ls ~/git/innanlab/gdc|grep gdc-user-token`;
if($tokenfile!~/./){die "!!ERROR!!: not exist token file\n";}
chomp ($normjson,$tumorjson,$normmanifest,$tumormanifest,$tokenfile);

$token="~/git/gdc_il/$tokenfile";
print "check manifest & jsonfile & token files\n";
if(`ls|grep out\.log` !~ /./){die "not put out log to file\n redo by writing log to out.log\n";}
=pod
mkdir './norm';
chdir './norm';
system("~/gdc-client download -m $pwd/$normmanifest -t $token");
mkdir '../tumor';
chdir '../tumor';
system("~/gdc-client download -m $pwd/$tumormanifest -t $token");
chdir '../';
if(`grep ERROR out.log` =~ /./){die "there are some ERROR by download cel files\n check out.log and redownload cel files\n";}
=cut
my $pwdn=`pwd`;chomp $pwdn;
if($pwd ne $pwdn){die "ERROR stopped at line 23 main.pl\n";}

system("curl --request POST --header \"Content-Type: application/json\" --data \@$tumorjson \'https://gdc-api.nci.nih.gov/legacy/files\' > response_tumorcel.tsv");
system("curl --request POST --header \"Content-Type: application/json\" --data \@$normjson \'https://gdc-api.nci.nih.gov/legacy/files\' > response_normcel.tsv");
my %response=();
open(NORM,"nkf -Lu response_normcel.tsv|") or die "ERROR normal response is not available\n";
open(TUMOR,"nkf -Lu response_tumorcel.tsv|") or die "ERROR tumor response is not availabel\n";;
open(FILE,">file_check.txt");
my $dummy=<NORM>;my @test=split(/\t/,$dummy);if(scalar(@test)!=14){die "ERROR:norm response is not 14 colums\n";}
$dummy=<TUMOR>;my@ttest=split(/\t/,$dummy);if(scalar(@ttest)!=14){die "ERROR:tumor response is not 14 colums\n";}#各々の1行目(colum name)を削除
while(<NORM>){
		chomp;
		my @line=split(/\t/,);
		if(exists $response{$line[0]}{'norm'}{file}){
				print FILE "$line[0] heve 2 or more norm files\t$line[3], $response{$line[0]}{norm}{sampletype}\n";
				if($line[1] eq "Blood Derived Normal"){
						$response{$line[0]}{'norm'}{'file'}=$line[5];
						$response{$line[0]}{'norm'}{'sampletype'}=$line[3];
						$response{$line[0]}{'norm'}{'uuid'}=$line[10];
				}
		}else{
				$response{$line[0]}{'norm'}{'file'}=$line[5];
				$response{$line[0]}{'norm'}{'sampletype'}=$line[3];
				$response{$line[0]}{'norm'}{'uuid'}=$line[10];
		}
}
close NORM;
while(<TUMOR>){
		chomp;
		my @line =split(/\t/,);
		if(exists $response{$line[0]}{'tumor'}{file}){
				print FILE "$line[0] heve 2 or more tumor files\t$line[2], $response{$line[0]}{tumor}{sampletype}\n";
		}else{
				$response{$line[0]}{'tumor'}{'file'}=$line[5];
				$response{$line[0]}{'tumor'}{'sampletype'}=$line[3];
				$response{$line[0]}{'tumor'}{'uuid'}=$line[10];
		}
}
close TUMOR;

open(NCL,">norm_cel_list.txt");
open(TCL,">tumor_cel_list.txt");
print NCL "cel_files\tfilename\tpatient\n";
print TCL "cel_files\tfilename\tpatient\n";

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
}
print FILE "\nThere is no norm file of $normn patient\n$norm\n\nThere is no tumor file of $tumorn patient\n$tumor\n";
close TCL;
close NCL;
close FILE;

system('sh ~/git/ascat_script/hg19_ascat/make_norm_gw6_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_script/hg19_ascat/scripts/split_lrr_baf.R norm_lrr_baf.txt norm_cel_list.txt $pwd");

system('sh ~/git/ascat_script/hg19_ascat/scripts/make_tumor_lrrbaf.sh 2>&1 > /dev/null');
system("Rscript --slave ~/git/ascat_script/hg19_ascat/scripts/split_lrr_baf.R tumor_lrr_baf.txt tumor_cel_list.txt $pwd");

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
		system("Rscript --slave ~/git/ascat_script/hg19_ascat/scripts/2sample_ascat.R $subdir $pwd $sex 2>&1 > /dev/null");
		print "doing $subdir ascat\n";
		unlink "ascat/$subdir/normal.LogR.txt";
		unlink "ascat/$subdir/normal.BAF.txt";
		unlink "ascat/$subdir/tumor.LogR.txt";
		unlink "ascat/$subdir/tumor.BAF.txt";
#fork end
		$pm->finish;
}

system("perl ~/git/ascat_script/hg19_ascat/scripts/annotate_ascat.pl");

exit;

