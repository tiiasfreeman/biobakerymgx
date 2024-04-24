process METAPHLAN_SGBTOGTDBPROFILE {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.1.0--pyhca03a8a_0' :
        'biocontainers/metaphlan:4.1.0--pyhca03a8a_0' }"

    input:
    tuple val(meta), path(metaphlan_profile)
    path (sgb2gtdb)

    output:
    tuple val(meta), path("${prefix}_gtdb_profile.txt") , emit: gtdb_profile
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    metaphlan_sgb_to_gtdb_profile.py \\
        -i ${metaphlan_profile} \\
        -d ./${sgb2gtdb} \\
        -o ${prefix}_gtdb_profile.txt \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | awk '{print \$3}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_gtdb_profile.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | awk '{print \$3}')
    END_VERSIONS
    """
}
