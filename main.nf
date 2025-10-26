process fastqc {
    publishDir "s3://aws-batch-input-bioinformatics/fastqc-results", mode: 'copy'

    input:
    path input

    output:
    path "*_fastqc.{zip,html}"

    script:
    """
    fastqc -q $input
    """
}

workflow {
   Channel.fromPath("s3://aws-batch-input-bioinformatics/transcriptomics/data/*fastq.gz") | fastqc
}
