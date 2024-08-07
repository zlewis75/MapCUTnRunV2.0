#!/bin/bash
#SBATCH --partition=batch
#SBATCH --mail-type=ALL
#SBATCH --mail-user=zlewis@uga.edu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=100gb
#SBATCH --time=8:00:00
#SBATCH --output=../MappingOutput/logs/%x.out
#SBATCH --error=../MappingOutput/logs/%x.err


cd $SLURM_SUBMIT_DIR

## remove files you don't need from config
source config.txt

###ADD a source file with path to FastqFiles
#variables imported from submission script
#accession=SRR#
#fastqPath=Path to folder containing folders of accessions, each containing one fastq; these are generated by ffq (https://github.com/UGALewisLab/downloadSRA.git)
#outdir=this is ../MappingData

###################
#start
####################################################

###################################
#input file variables
  read1="${fastqPath}/${accession}*_R1_001.fastq.gz"
  read2="${fastqPath}/${accession}*_R2_001.fastq.gz"

#make output file folders
trimmed="${outdir}/TrimmedFastQs/${accession}"
mkdir $trimmed

tmp="${outdir}/tempFile"
bamdir="${outdir}/bamFiles"
mkdir "${bamdir}"

bwDir="${outdir}/bigWig"
mkdir "${bwDir}"

PeakDir="${outdir}/Peaks/${accession}"

#make variables for output file names
bam="${bamdir}/${accession}.bam"
bigwig="${bwDir}/${accession}"
peak="$PeakDir/${accession}"

name=${bam/%_S[1-12]*_L001_R1_001_val_1.fq.gz/}


############# Read Trimming ##############
#remove adaptors, trim low quality reads (default = phred 20), length > 25

##fastq files from the ebi link are in folders that either have one file with a SRR##.fastq.gz or a SRR##_1.fastq.gz ending, or have two files with a SRR##_1.fastq.gz ending or a SRR##_2.fastq.gz ending
#or have three files with a SRR##_1.fastq.gz, SRR##_2.fastq.gz and SRR##.fastq.gz ending. In this case, the third file corresponds to unpaired reads that the depositers mapped.

#JGI files should have a SRR##_1.fastq.gz ending and a SRR##_2.fastq.gz file

##################
#Trimming
#################
	  ml Trim_Galore/0.6.7-GCCcore-11.2.0

	  trim_galore --illumina --fastqc --paired --length 25 --basename ${accession} --gzip -o $trimmed $read1 $read2
	  wait



ml SAMtools/1.16.1-GCC-11.3.0 
ml BWA/0.7.17-GCCcore-11.3.0
#

#make directory to store temporary files written by samtools sort
mkdir -p ${tmp}/${accession}

bwa mem -M -v 3 -t $THREADS $GENOME ${trimmed}/*val_1.fq.gz ${trimmed}/*val_2.fq.gz | samtools view -bhSu - | samtools sort -@ $THREADS -T ${bamdir}/${accession}/ -o "$bam" -
samtools index "$bam"

#delete directory written by samtools sort
rm -r ${tmp}/${accession}

ml deepTools/3.5.2-foss-2022a
#Plot all reads
bamCoverage -p $THREADS -bs $BIN --normalizeUsing BPM --minMappingQuality 20 --smoothLength $SMOOTH -of bigwig -b "$bam" -o "${bigwig}.bin_${BIN}.smooth_${SMOOTH}Bulk.bw"

#plot mononucleosomes
bamCoverage -p $THREADS --MNase -bs 1 --normalizeUsing BPM --minMappingQuality 20 --smoothLength 25 -of bigwig -b "$bam" -o "${bigwig}.bin_${BIN}.smooth_${SMOOTH}_MNase.bw"

#call Peaks
module load MACS3/3.0.0b1-foss-2022a-Python-3.10.4

#using --nolambda paramenter to call peaks without control
macs3 callpeak -t "${bam}" -f BAMPE -n "${accession}" --broad -g 41037538 --broad-cutoff 0.1 --outdir "${PeakDir}" --min-length 800 --max-gap 500 --nolambda


