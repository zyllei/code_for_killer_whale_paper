#!/bin/sh

###usage##
#  sh shell out_prefix VCF type 
###

# ******************************************
# 0. User settings 
# ******************************************

prefix="$1"     # out vcf file
in_vcf="$2"     # input raw vcf file
HQ="$3"         # high quality dababase
var_type="$4"   # SNP or INDEL

if [ $prefix ] || [ $in_vcf ] || [ $HQ ] || [ $var_type ]
then
	echo "start sentieon ..."
else
	echo "sh sentieon_quickstart_VQSR.sh <ouput prefix> <input vcf file> <high-quality database> <SNP/INDEL>"
	exit
fi

# deal with path
opt_dirname=`cd \`dirname $prefix\`;pwd`
opt_basname=`basename $prefix`
prefix="$opt_dirname/$opt_basname"

in_vcf=`readlink -f $in_vcf`
HQ=`readlink -f $HQ`

#if [ ! -f $in_vcf ]; then
#    echo "VCF not exist"
#    exit 1
#fi

# user defult 
#   Number of threads. You can get the number of cpu cores by running nproc  
nt=48
#   Fasta reference file
fasta=./ref_genome.fa

# default set
sentieon=/share/app/st_bigdata/Sentieon/Sentieon
bgzip=./software/variation/htslib-1.4.1/bin/bgzip
tabix=./software/variation/htslib-1.4.1/bin/tabix
logfile="$prefix.$var_type.VQSR_$(date +"%Y%m%d%H%M").log"

# there is no need to modify the rest of the script
# ******************************************
# 0. input locations
# ******************************************

# Test if location of the Sentieon installation directory is set
set -x
exec 2>$logfile

# ******************************************
# 1. VQSR stage for SNP or INDEL
# 
# two tools used: VarCal and ApplyVarCal
#
# Produces Picard standard metrics of the input sequence and alignment. 
# ******************************************
start_time_mod=$(date +%s)

# calcuate VQSR using VarCal
if [ $var_type = "SNP" ]; then
    $sentieon driver -r $fasta -t $nt --algo VarCal -v $in_vcf --tranches_file $prefix.snp.tranches --resource $HQ --resource_param HQ,known=false,training=true,truth=true,prior=10.0 --var_type SNP --annotation QD --annotation MQRankSum --annotation ReadPosRankSum --annotation SOR --annotation MQ --annotation FS --max_gaussians 8 $prefix.snp.recal.vcf
    #$sentieon driver -r $fasta -t $nt --algo VarCal -v $in_vcf --tranches_file $prefix.snp.tranches --resource $HQ --resource_param HQ,known=false,training=true,truth=true,prior=10.0 --var_type SNP --annotation QD --annotation MQRankSum --annotation ReadPosRankSum --annotation SOR --annotation MQ --annotation FS --annotation DP --annotation InbreedingCoeff --max_gaussians 8 $prefix.snp.recal.vcf
    $sentieon driver -r $fasta -t $nt --algo ApplyVarCal -v $in_vcf --recal $prefix.snp.recal.vcf --tranches_file $prefix.snp.tranches --var_typ SNP --sensitivity 99.9 $prefix.snp.VQSR.vcf
fi

if [ $var_type = "INDEL" ]; then
    $sentieon driver -r $fasta -t $nt --algo VarCal -v $in_vcf --tranches_file $prefix.indel.tranches --resource $HQ --resource_param HQ,known=false,training=true,truth=true,prior=10.0 --var_type INDEL --annotation QD --annotation MQRankSum --annotation ReadPosRankSum --annotation SOR --annotation MQ --annotation FS --max_gaussians 4 $prefix.indel.recal.vcf
    #$sentieon driver -r $fasta -t $nt --algo VarCal -v $in_vcf --tranches_file $prefix.indel.tranches --resource $HQ --resource_param HQ,known=false,training=true,truth=true,prior=10.0 --var_type INDEL --annotation QD --annotation MQRankSum --annotation ReadPosRankSum --annotation SOR --annotation MQ --annotation FS --annotation DP --annotation InbreedingCoeff --max_gaussians 4 $prefix.indel.recal.vcf
    $sentieon driver -r $fasta -t $nt --algo ApplyVarCal -v $in_vcf --recal $prefix.indel.recal.vcf --tranches_file $prefix.indel.tranches --var_typ INDEL --sensitivity 99.0 $prefix.indel.VQSR.vcf
fi

end_time_mod=$(date +%s)
if [ "$OSTYPE" = "darwin"* ]; then start_date=$(date -j -f "%s" $start_time_mod); else start_date=$(date -d @$start_time_mod); fi
if [ "$OSTYPE" = "darwin"* ]; then end_date=$(date -j -f "%s" $end_time_mod); else end_date=$(date -d @$end_time_mod); fi
echo "Module VQSR(VarCal+ApplyVarCal) Started: "$start_date"; Ended: "$end_date"; Elapsed time: "$(($end_time_mod - $start_time_mod))" sec">>$logfile
