#!/bin/bash
#SBATCH --job-name=demuxalot_launcher
#SBATCH --output=demuxalot_launcher_%j.log
#SBATCH --error=demuxalot_launcher_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

pwd=$(pwd)
echo "Current directory: $pwd"

find ./2config_* -name possorted_genome_bam.bam | while read -r d; do
  dir_in=$d
  d=${d#./}
  dir_in=${dir_in%/possorted_genome_bam.bam}
  dir_in=${dir_in#./}
  IFS=/ read -r name dirx file <<< "$d"

  dir="DEMUX2"
  n=${name##*_}
  
  job_script="demuxalot_job_$n.sh"
  
  cat <<- EOF > $job_script
#!/bin/bash
#SBATCH --job-name=demuxalot_$n
#SBATCH --output=demuxalot_$n_%j.log
#SBATCH --error=demuxalot_$n_%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

singularity exec /data/chi/bin/Demuxafy.sif bash << 'SINGULARITY_EOF'

pwd=\$(pwd)
echo "Current directory: \$pwd"

cmd2="zcat \$pwd/$dir_in/filtered_feature_bc_matrix/barcodes.tsv.gz > \$pwd/$dir_in/filtered_feature_bc_matrix/mod_sample_barcodes.csv"
echo "\$cmd2"
eval "\$cmd2"

mkdir -p DEMUX2/2config_$n

comd="Demuxalot.py -a \$pwd/$d -v \$pwd/v2args_418_minus_P205235.vcf -b \$pwd/$dir_in/filtered_feature_bc_matrix/mod_sample_barcodes.csv -o \$pwd/$dir/2config_$n -n \$pwd/ind.txt -r True"
echo "\$comd"
eval "\$comd"

SINGULARITY_EOF
EOF

  # Submit the generated job script
  sbatch $job_script

done

