process KNEADDATA_KNEADDATA {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.12.0--pyhdfd78af_1':
        'biocontainers/kneaddata:0.12.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(fastq_gz)
    path (kneaddata_db)

    output:
    tuple val(meta), path("${prefix}_kneaddata_paired_{1,2}.fastq.gz")  , emit: preprocessed_reads
    tuple val(meta), path("${prefix}_kneaddata.log")                    , emit: kneaddata_log
    path "versions.yml"                                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # install trimmomatic
    curl \\
    -o Trimmomatic-0.33.zip \\
    http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.33.zip

    # unzip trimmomatic executable
    unzip Trimmomatic-0.33.zip

    kneaddata \\
        --input1 ${fastq_gz[0]} \\
        --input2 ${fastq_gz[1]} \\
        --output ./ \\
        --output-prefix ${prefix}_kneaddata \\
        --reference-db ${kneaddata_db} \\
        --threads ${task.cpus} \\
        --trimmomatic ./Trimmomatic-0.33 \\
        $args

    gzip *.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*v//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_kneaddata_paired_1.fastq
    touch ${prefix}_kneaddata_paired_2.fastq
    gzip ${prefix}_kneaddata_paired_*.fastq
    touch ${prefix}_kneaddata.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*v//' ))
    END_VERSIONS
    """
}
