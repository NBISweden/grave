process FREEBAYES {

	// Directives

	debug false
	tag "${meta.id}.${meta.repeat}"
	label 'process_medium'
	container 'oras://community.wave.seqera.io/library/bamtools_bcftools_freebayes_htslib:cf23d815667a73b4'
    publishDir path: 'output/variant_calling/mapped_samples/freebayes', mode: 'move'

	// I/O & script

	input:
	path ref_path_files
	tuple path(reference_fasta), path(fasta_index)
	tuple val(meta), path(surjected_bam), path(bam_index)

	output:
	tuple val(meta), path("*.vcf.gz")
	tuple val(task.process), val('bamtools'), eval('bamtools --version | head -n 2 | tail -n 1 | sed "s/bamtools //"'), topic: versions
	tuple val(task.process), val('freebayes'), eval('freebayes --version | sed "s/version.*v//"'), topic: versions
	tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions
	tuple val(task.process), val('bcftools'), eval('bcftools version | head -n 1 | sed "s/.* //"'), topic: versions

	when:
	params.freeBayes == true

	script:
	if (!params.refPaths)	// Assume single reference sample
		"""

		# Generate equal coverage regions for parallelization

    		bamtools coverage -in ${surjected_bam} | coverage_to_regions.py ${fasta_index} 500 > ${reference_fasta}.regions

		# Run FreeBayes against the single reference sample

			freebayes-parallel ${reference_fasta}.regions \
				${task.cpus} \
				--pooled-continuous \
				--genotype-qualities \
				--fasta-reference ${reference_fasta} \
				--min-alternate-count ${params.minimumAlleleSupport} \
				--min-alternate-fraction ${params.minFraction} \
				--ploidy ${params.samplePloidy} \
				--max-complex-gap ${params.maxComplexGap} \
				${surjected_bam} | \
				bgzip --threads ${task.cpus} > \
				${meta.id}.${meta.repeat}.raw.vcf.gz

		# Norm and sort

			bcftools norm -f ${reference_fasta} ${meta.id}.${meta.repeat}.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.norm.vcf.gz

		"""

	else if (params.refPaths)
		"""

		# Get reference sample prefixes from '.paths' files

			for i in *.paths
				do
					prefix=`echo \$i | sed 's/\\.paths//'`
					echo \$prefix >> referenceSamplePrefixes.txt
				done

		# Run FreeBayes workflow against each reference sample

			while read prefix

				do

					# Generate equal coverage regions for parallelization

						bamtools coverage -in ${surjected_bam} | coverage_to_regions.py \$prefix.fasta.fai 500 > \$prefix.regions

					# Run FreeBayes

						freebayes-parallel \$prefix.regions \
							${task.cpus} \
							--pooled-continuous \
							--genotype-qualities \
							--fasta-reference \$prefix.fasta \
							--min-alternate-count ${params.minimumAlleleSupport} \
							--min-alternate-fraction ${params.minFraction} \
							--ploidy ${params.samplePloidy} \
							--max-complex-gap ${params.maxComplexGap} \
							${surjected_bam} | \
							bgzip --threads ${task.cpus} > \
							${meta.id}.${meta.repeat}.\$prefix.raw.vcf.gz

					# Norm and sort

						bcftools norm -f \$prefix.fasta ${meta.id}.${meta.repeat}.\$prefix.raw.vcf.gz | bcftools sort | bgzip --threads ${task.cpus} > ${meta.id}.${meta.repeat}.\$prefix.norm.vcf.gz

				done < referenceSamplePrefixes.txt

		"""

}
