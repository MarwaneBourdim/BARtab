// use cutadapt to filter for length
process CUTADAPT_READS{
  tag "cutadapt on $sample_id"
  label "process_low"
  publishDir "${params.outdir}/trimmed_reads/", mode: 'symlink'

  input:
    tuple val(sample_id), path(reads)

  output:
    tuple val(sample_id), path("${sample_id}.trimmed.fastq"), emit: reads
    path "${sample_id}.cutadapt.log", emit: log
  
  script:
  if(params.mode == "single-cell") {
    // TODO check parameters
    """
    cutadapt -j ${params.threads} -g "${params.upconstant}...${params.downconstant}" --trimmed-only --max-n=0 -e 0.2 -m 20 ${reads} > ${sample_id}.trimmed_1.fastq 2> ${sample_id}.cutadapt.log
    cutadapt -j ${params.threads} -g ${params.upconstant} --trimmed-only --max-n=0 -e 0.2 -m 20 ${reads} > ${sample_id}.trimmed_2.fastq 2>> ${sample_id}.cutadapt.log
    cutadapt -j ${params.threads} -a ${params.downconstant} --trimmed-only --max-n=0 -e 0.2 -m 20 ${reads} > ${sample_id}.trimmed_3.fastq 2>> ${sample_id}.cutadapt.log
    cat ${sample_id}.trimmed_*.fastq > ${sample_id}.trimmed.fastq
    """
  }
  // TODO replace params.merge
  else if( params.merge )
    """
    cutadapt -j ${params.threads} -g "${params.upconstant}...${params.downconstant}" --trimmed-only --max-n=0 -m 15 ${reads} > ${sample_id}.trimmed.fastq 2> ${sample_id}.cutadapt.log
    """
  else if( params.constants == "both" )
    """
    cutadapt -j ${params.threads} -g "${params.upconstant}...${params.downconstant}" --trimmed-only --max-n=0 -m 15 ${reads} > ${sample_id}.trimmed.fastq 2> ${sample_id}.cutadapt.log
    """
  else if( params.merge && params.constants == "up" )
    """
    cutadapt -j ${params.threads} -g "${params.upconstant}" --trimmed-only --max-n=0 -m 15 ${reads} > ${sample_id}.trimmed.fastq 2> ${sample_id}.cutadapt.log
    """
  else
    """
    cutadapt -j ${params.threads} -g "${params.upconstant}" --trimmed-only --max-n=0 -m 15 ${reads} > ${sample_id}.trimmed.fastq 2> ${sample_id}.cutadapt.log
    """
}