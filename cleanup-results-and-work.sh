# Work and results cleanup

shopt -s extglob

rm -rf results

cd work

rm -rf  !(apptainer)
