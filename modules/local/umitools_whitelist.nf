process UMITOOLS_WHITELIST {
  tag "umi_tools whitelist on $sample_id"
  label "process_med"
  publishDir "${params.outdir}/extract", mode: 'symlink'

  input:
    tuple val(sample_id), path(reads)

  output:
    tuple val(sample_id), path("${sample_id}_whitelist.txt")

  script:
    """
    umi_tools whitelist --stdin ${reads[0]} \\
      --bc-pattern=CCCCCCCCCCCCCCCCNNNNNNNNNN \\
      --log2stderr > ${sample_id}_whitelist.txt
    """
}