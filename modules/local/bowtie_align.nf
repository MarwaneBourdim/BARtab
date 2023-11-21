process BOWTIE_ALIGN {
    tag "$sample_id"
    label "$params.mode" == "single-cell" ? "process_medium_sc" : "process_medium_bulk"

    input:
        tuple val(refname), path(ref_files)
        tuple val(sample_id), path(reads)

    output:
        tuple val(sample_id), path("${sample_id}.mapped.sam"), emit: mapped_reads
        tuple val(sample_id), path("${sample_id}.unmapped.fastq.gz"), emit: unmapped_reads, optional: true
        path "${sample_id}.bowtie.log", emit: log

    script:
        // the only difference is output file for unmapped reads and zipping unmapper reads
        if (params.cluster_unmapped) {
            """
            bowtie \\
            -x ${refname} \\
            -q ${reads} \\
            -p ${task.cpus} \\
            -v ${params.alnmismatches} \\
            --norc \\
            -t \\
            --un ${sample_id}.unmapped.fastq \\
            -a --best --strata -m1 \\
            -S ${sample_id}.mapped.sam \\
            2> ${sample_id}.bowtie.log

            pigz -p ${task.cpus} ${sample_id}.unmapped.fastq
            """
        } else {
            """
            bowtie \\
            -x ${refname} \\
            -q ${reads} \\
            -p ${task.cpus} \\
            -v ${params.alnmismatches} \\
            --norc \\
            -t \\
            -a --best --strata -m1 \\
            -S ${sample_id}.mapped.sam \\
            2> ${sample_id}.bowtie.log
            """
        }

}