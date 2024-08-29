shopt -s extglob

rm .nextflow.log*

cd work

rm -rf  !(apptainer)

cd ..
