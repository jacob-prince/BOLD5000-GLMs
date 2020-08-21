#!/bin/sh
#SBATCH -N 1      # nodes requested
#SBATCH -n 1      # tasks requested
#SBATCH -c 3     # cores requested
#SBATCH --partition=gpu
#SBATCH --job-name GLM
#SBATCH --mem=64G  # memory 
#SBATCH --output logfiles/sbatch-logfile-%j.txt  # send stdout to outfile
#SBATCH --time=12:00:00
#SBATCH --exclude=mind-1-[1,3,5]

module load matlab-9.5

matlab -nodisplay -nosplash -r "step1_run_GLMs_v4 $1 $2 $3; exit"