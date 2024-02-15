process KNEADDATA_READCOUNTS {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.12.0--pyhdfd78af_1':
        'biocontainers/kneaddata:0.12.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(kneaddata_logs)

    output:
    path("${prefix}_kneaddata_read_counts.tsv") , emit: kneaddata_read_counts
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    kneaddata_read_count_table \\
        --input ./ \\
        --output ${prefix}_kneaddata_read_counts.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*v//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_kneaddata_read_counts.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*v//' ))
    END_VERSIONS
    """
}
