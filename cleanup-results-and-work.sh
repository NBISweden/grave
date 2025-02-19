shopt -s extglob

rm -rf output/

cd work

rm -rf  !(apptainer)

cd ..
