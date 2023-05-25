process UMITOOLS_EXTRACT {
  tag "umi_tools extract on $sample_id"
  label "process_medium"
  publishDir "${params.outdir}/extract", mode: 'symlink'

  input:
    tuple val(sample_id), path(reads)
    tuple val(sample_id), path(whitelist)

  output:
    tuple val(sample_id), path("${sample_id}_R2_extracted.fastq")

  script:
    """
    umi_tools extract --bc-pattern=CCCCCCCCCCCCCCCCNNNNNNNNNN \\
      --stdin ${reads[0]} --stdout ${sample_id}_extracted.fastq \\
      --read2-in ${reads[1]} --read2-out=${sample_id}_R2_extracted.fastq \\
      --whitelist=${whitelist}
    """
}