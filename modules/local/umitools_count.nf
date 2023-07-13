process UMITOOLS_COUNT {
  tag "umi_tools count on $sample_id"
  label "process_medium"
  publishDir "${params.outdir}/counts", mode: 'copy'

  input:
    // index file needs to be linked to work directory
    tuple val(sample_id), path(bam), path(bai)

  output:
    tuple val(sample_id), path("${sample_id}.counts.tsv"), emit: counts
    path("${sample_id}_counts.log"), emit: log
    
  script:
    """
    umi_tools count \\
    --per-contig --per-cell \\
    --edit-distance-threshold=${params.umi_dist} \\
    --random-seed=10101 \\
    -I ${bam} \\
    -S ${sample_id}.counts.tsv \\
    -L ${sample_id}_counts.log
    """  
}