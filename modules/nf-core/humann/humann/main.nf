process HUMANN_HUMANN {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.8--pyh7cba7a3_0':
        'biocontainers/humann:3.8--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(fastq)
    path             (chocophlan_db_dir)
    path             (uniref_db_dir)

    output:
    tuple val(meta), path("*._genefamilies.tsv"),  emit: genefamilies
    tuple val(meta), path("*._pathcoverage.tsv"),  emit: pathcoverage
    tuple val(meta), path("*._pathabundance.tsv"), emit: pathabundance
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann \\
    --input ${fastq} \\
    --nucleotide-database $chocophlan_db_dir \\
    --protein-database $uniref_db_dir \\
    --output humann_results \\
    ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        modules: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    touch "*._genefamilies.tsv"
    touch "*._pathcoverage.tsv"
    touch "*._pathabundance.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        modules: \$(samtools --version |& sed '1!d ; s/samtools //')
    END_VERSIONS
    """
}