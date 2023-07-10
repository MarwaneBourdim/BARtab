include { SOFTWARE_CHECK } from '../modules/local/software_check'
include { FASTQC } from '../modules/local/fastqc'
// include { FILTER_READS } from '../modules/local/filter_reads'
include { UMITOOLS_WHITELIST } from '../modules/local/umitools_whitelist'
include { UMITOOLS_EXTRACT } from '../modules/local/umitools_extract'
include { PROCESS_BAM } from '../modules/local/process_bam'
include { CUTADAPT_READS } from '../modules/local/cutadapt_reads'
include { BUILD_BOWTIE_INDEX } from '../modules/local/build_bowtie_index'
include { BOWTIE_ALIGN } from '../modules/local/bowtie_align'
include { FILTER_ALIGNMENTS } from '../modules/local/filter_alignments'
include { RENAME_READS } from '../modules/local/rename_reads'
include { RENAME_READS_SAW } from '../modules/local/rename_reads_saw'
include { SAMTOOLS } from '../modules/local/samtools'
include { UMITOOLS_COUNT } from '../modules/local/umitools_count'
include { PARSE_BARCODES_SC } from '../modules/local/parse_barcodes_sc'
include { MULTIQC } from '../modules/local/multiqc'

workflow SINGLE_CELL {

    main:

        if (params.input_type == "bam") {
            readsChannel = Channel.fromPath( "${params.indir}/*.bam" )
                // creates the sample name
                .map { file -> tuple( file.baseName.replaceAll(/\.bam/, ''), file ) }
                .ifEmpty { error "Cannot find any *.bam files in: ${params.indir}" }
        } else if (params.input_type == "fastq" & params.pipeline == "saw") {
            readsChannel = Channel.fromPath( "${params.indir}/*.fq.gz" )
                .map { file -> tuple( file.baseName.replaceAll(/\.fq\.gz/, ''), file ) }
                .ifEmpty { error "Cannot find any *.fq.gz files in: ${params.indir}" }
        } else {
            readsChannel = Channel.fromFilePairs( "${params.indir}/*_R{1,2}*.{fastq,fq}.gz" )
                .ifEmpty { error "Cannot find any *_R{1,2}.{fastq,fq}.gz files in: ${params.indir}" }
        }

        reference = file(params.ref)

        params.multiqc_config = "$baseDir/assets/multiqc_config.yaml"

        multiqcConfig = Channel.fromPath(params.multiqc_config, checkIfExists: true)

        output = Channel.fromPath( params.outdir, type: 'dir', relative: true)

        SOFTWARE_CHECK()

        if (params.input_type == "fastq" & params.pipeline == "saw") {
            r2_fastq = readsChannel

        } else if (params.input_type == "fastq") {
            FASTQC(readsChannel)

            // filtering reads for quality
            // TODO

            // extract reads with cell barcode from fastq input
            UMITOOLS_WHITELIST(readsChannel)

            r2_fastq = UMITOOLS_EXTRACT(readsChannel.combine(UMITOOLS_WHITELIST.out.whitelist, by: 0)).reads

        } else if (params.input_type == "bam") {
            // extract reads with cell barcode and UMI and convert to fastq
            r2_fastq = PROCESS_BAM(readsChannel).reads
        }

        CUTADAPT_READS(r2_fastq)

        bowtie_index = BUILD_BOWTIE_INDEX(reference)
        BOWTIE_ALIGN(bowtie_index, CUTADAPT_READS.out.reads)

        // filter alignments if barcode has fixed length
        mapped_reads = params.barcode_length ? FILTER_ALIGNMENTS(BOWTIE_ALIGN.out.mapped_reads) : BOWTIE_ALIGN.out.mapped_reads

        if (params.pipeline == "saw") {
            // modify read header for umi_tools
            mapped_reads = RENAME_READS_SAW(FILTER_ALIGNMENTS.out)
        } else if (params.input_type == "bam") {
            // add CB and UMI info in header
            mapped_reads = RENAME_READS(mapped_reads.combine(readsChannel, by: 0))

        } else {
            mapped_reads = FILTER_ALIGNMENTS.out
        }
        SAMTOOLS(mapped_reads)

        UMITOOLS_COUNT(SAMTOOLS.out)

        PARSE_BARCODES_SC(UMITOOLS_COUNT.out.counts.combine(BOWTIE_ALIGN.out.mapped_reads, by: 0))

        // pass counts to multiqc so it waits to run until all samples are processed
        // MULTIQC(multiqcConfig, output, PARSE_BARCODES_SC.out.counts)
}
