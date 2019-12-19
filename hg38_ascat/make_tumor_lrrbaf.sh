#~/ascat/apt-1.19.0-x86_64-apple-yosemite/bin/apt-probeset-genotype -c ~/ascat/apt-1.19.0-x86_64-apple-yosemite/lib/GenomeWideSNP_6.cdf -a birdseed --read-models-birdseed ~/ascat/apt-1.19.0-x86_64-apple-yosemite/lib/GenomeWideSNP_6.birdseed.models --special-snps ~/ascat/apt-1.19.0-x86_64-apple-yosemite/lib/GenomeWideSNP_6.specialSNPs --out-dir apt_tumor --cel-files tumor_cel_list.txt

#~/ascat/apt-1.19.0-x86_64-apple-yosemite/bin/apt-probeset-summarize --cdf-file ~/ascat/apt-1.19.0-x86_64-apple-yosemite/lib/GenomeWideSNP_6.cdf --analysis quant-norm.sketch=50000,pm-only,med-polish,expr.genotype=true --target-sketch ~/ascat/gw6/lib/hapmap.quant-norm.normalization-target.txt --out-dir apt_tumor --cel-files tumor_cel_list.txt

#fgrep male apt/birdseed.report.txt | cut -f 1,2 > file_sex

#~/ascat/gw6/bin/generate_affy_geno_cluster.pl apt/birdseed.calls.txt apt/birdseed.confidences.txt apt/quant-norm.pm-only.med-polish.expr.summary.txt -locfile ~/ascat/gw6/lib/affygw6.hg19.pfb -sexfile file_sex -out gw6.genocluster

~/ascat/gw6/bin/normalize_affy_geno_cluster.pl gw6.genocluster apt_tumor/quant-norm.pm-only.med-polish.expr.summary.txt -locfile ~/ascat/gw6/lib/affygw6.hg38.pfb -out tumor_lrr_baf.txt
