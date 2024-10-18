shopt -s extglob

rm -rf .nextflow.log* output/

cd work

rm -rf  !(apptainer)

cd ..
