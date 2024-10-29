process COMPUTESNARLS {

        // Directives

        debug false
        label 'process_medium'
		container 'oras://community.wave.seqera.io/library/vg:1.59.0--92074ade48692ef2'

        // I/O & script

        input:
        path graph

        output:
        path "${graph}.snarls", emit: ch_snarls

        script:
		"""

		# Compute graph snarls for genotyping tasks

			vg snarls -t ${task.cpus} --include-trivial ${graph} > ${graph}.snarls

		"""

}
