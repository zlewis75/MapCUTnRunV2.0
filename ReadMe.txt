This repository should be cloned into a directory for proccessing a set of files with each sample downloaded into a subdirectory

cloning the repository will create a directory named MapCUTnRunV2.0. The same directory should contain a folder named /FastqFiles

To run:

1. $ cd ./MapCUTnRunV2.0
2. $ nohup sh Submit_JgiSampleJob.sh "/Path/To/List/of/Samples" #this should be the same list used to demultiplex samples to create the fastq files

Output

This file will create a folder called MappingOutput in the directory above the submission directory. 
