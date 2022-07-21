#step1. genome assembly using Nextdenovo with nanopore data
sh work.sh

#step2. genome polish using short reads
sh bwa.sh
sh polish.sh

#step3. anchor scaffolds to chromosomes using Hic sequencing data
sh Juicer.sh
sh 3ddna.sh