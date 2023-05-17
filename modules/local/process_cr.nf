// Filters reads from BAM file that contain cell barcode (only contains R2 from CR)
// converts to fastq file
// https://kb.10xgenomics.com/hc/en-us/articles/360022448251-How-to-filter-the-BAM-file-produced-by-10x-pipelines-with-a-list-of-barcodes-
process PROCESS_CR {
    tag { "bam to fastq ${sample_id}" }
    // label "process_low"
    publishDir "${params.outdir}/process_cr/", mode: 'symlink'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_R2.fastq.gz"), emit: reads

    script:
    """
    # Save the header lines
    samtools view -H $bam > SAM_header.sam

    # Filter alignments. Use LC_ALL=C to set C locale instead of UTF-8
    samtools view -@ ${params.threads} $bam | LC_ALL=C grep 'CB:Z:' | LC_ALL=C grep 'UB:Z:' > filtered_SAM_body.sam

    # Combine header and body
    cat SAM_header.sam filtered_SAM_body.sam > ${sample_id}.filtered.sam

    # Convert filtered.sam to BAM format
    # samtools view -@ ${params.threads} -b ${sample_id}.filtered.sam > ${sample_id}.filtered.bam

    # convert BAM to fastq. CR output only contains R2
    samtools fastq -@ ${params.threads} ${sample_id}.filtered.sam -0 ${sample_id}_R2.fastq.gz

    rm SAM_header.sam filtered_SAM_body.sam
    """
}
