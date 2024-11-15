process DEEPVARIANT {

	// Directives

	debug true
	tag "${meta.id}.${meta.repeat}"
	label 'process_high'
	container 'docker://google/deepvariant:1.6.1'

	// I/O & script

	input:
	tuple val(meta), path(surjected_bams)

	output:
	// TODO: VCFS
	tuple val(task.process), val('deepvariant'), eval('/opt/deepvariant/bin/run_deepvariant --version 2>/dev/null | sed "s/.*version //"'), topic: versions

	script:
	if (!params.refPaths)	// Assume single reference sample
		"""

		echo "This will be a DeepVariant process"

			# /opt/deepvariant/bin/run_deepvariant --helpshort

		"""

	else if (params.refPaths) // FIXME: may not need the else if, surjection now moved out
		"""

			echo "This will be a deepvariant process acting on multiple reference samples"

			# /opt/deepvariant/bin/run_deepvariant --helpshort

		"""

}
