process HUMANN_JOINTABLES {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.8--pyh7cba7a3_0':
        'biocontainers/humann:3.8--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(genefamilies)
    tuple val(meta), path(pathcoverage)
    tuple val(meta), path(pathabundance)

    output:
    tuple val(meta), path("*.humann_genefamilies.tsv"),     emit: humann_genefamilies
    tuple val(meta), path("*.humann_pathabundance.tsv"),    emit: humann_pathabundance
    tuple val(meta), path("*.humann_pathcoverage.tsv"),     emit: humann_pathcoverage
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann_join_tables \\
    --input ${genefamilies} \\
    --output humann_genefamilies.tsv \\
    --file_name genefamilies_relab \\
    ${args}

    humann_join_tables \\
    --input ${pathcoverage} \\
    --output humann_pathcoverage.tsv \\
    --file_name pathcoverage \\
    ${args}

    humann_join_tables \\
    --input ${pathabundance} \\
    --output humann_pathabundance.tsv \\
    --file_name pathabundance_relab \\
    ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch "*.humann_genefamilies.tsv"
    touch "*.humann_pathabundance.tsv"
    touch "*.humann_pathcoverage.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}