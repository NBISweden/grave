pixi install

# Verify ipykernel
pixi run python -c "import ipykernel; print('ipykernel ok:', ipykernel.__version__)"

# Register kernel
pixi run python -m ipykernel install --user \
    --name grave-pixi \
    --display-name "grave (pixi)"

# Verify
pixi run jupyter kernelspec list

# Echo instructions
echo && echo "Note: The crucial step above is also available as pixi task (pixi run kernel-register)"
echo && echo "You can now run via pixi run quarto render file.qmd"
echo
echo "For interactive cell execution, we need to run via the IDE extensions (get quarto, python, and jupyter), not quarto front matter"
echo "Point the Python extension to:"
echo && echo "Ctrl+Shift+P → Python: Select Interpreter -> Enter interpreter path -> /path/to/grave/benchmarking/statistical_plotting/.pixi/envs/default/bin/python"
echo && echo "Reload window: Ctrl+Shift+P → Developer: Reload Window"
echo && echo "Finally, attempt to run a cell. In the interactive window that opens, where there is a kernel option: click -> select another kernel -> Jupyter Kernel -> grave (pixi)"
