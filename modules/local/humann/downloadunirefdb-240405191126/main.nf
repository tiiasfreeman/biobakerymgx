process HUMANN_DOWNLOADUNIREFDB {
    tag "${params.uniref_db_version}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.8--pyh7cba7a3_0':
        'quay.io/biocontainers/humann:3.8--pyh7cba7a3_0' }"

    output:
    path "${prefix}/uniref/"    , emit: uniref_db_dir
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "uniref_db_${params.uniref_db_version}"
    """
    mkdir -p ${prefix}

    # https_proxy=http://klone-dip1-A-ib:3128
    # export https_proxy
    humann_databases \\
        --download uniref ${params.uniref_db_version} \\
        ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "uniref_db_${params.uniref_db_version}"
    """
    mkdir -p ${prefix}/uniref/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
