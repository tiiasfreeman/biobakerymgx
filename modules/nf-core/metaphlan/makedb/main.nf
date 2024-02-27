process METAPHLAN_MAKEDB {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.1.0--pyhca03a8a_0' :
        'biocontainers/metaphlan:4.1.0--pyhca03a8a_0' }"

    output:
    path "${params.metaphlan_db_version}"   , emit: db
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    https_proxy=http://klone-dip1-A-ib:3128
    export https_proxy
    metaphlan \\
        --install \\
        --index ${params.metaphlan_db_version} \\
        --bowtie2db ${params.metaphlan_db_version} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | awk '{print \$3}')
    END_VERSIONS
    """
    stub:
    """
    mkdir ${params.metaphlan_db_version}
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.1.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.2.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.3.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.4.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.fna.bz2
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.pkl
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.rev.1.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}.rev.2.bt2l
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}_VINFO.csv
    touch ${params.metaphlan_db_version}/${params.metaphlan_db_version}_VSG.fna

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | awk '{print \$3}')
    END_VERSIONS
    """
}


