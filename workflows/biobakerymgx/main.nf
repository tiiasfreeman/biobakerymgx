/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


//
// SUBWORKFLOWS: Local subworkflows
//
include { FASTQ_READ_PREPROCESSING_KNEADDATA } from '../../subworkflows/kneaddata/main'
// TODO: Add metaphlan/download module
// TODO: Add metaphlan/metaphlan module
// TODO: Add metaphlan/mergetables module


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CAT_FASTQ } from '../../modules/nf-core/modules/cat/fastq/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BIOBAKERYMGX {

    take:
    fastq_gz    // [ [ meta ], [ read_1.fastq.gz, read_2.fastq.gz ] , paired-end reads (mandatory)

    main:
    ch_versions = Channel.empty()


    /*-----------------------------------------------------------------------------------
        Read-preprocessing: KneadData
    -----------------------------------------------------------------------------------*/
    //
    // SUBWORKFLOW: KneadData
    //
    if ( params.run_kneaddata ) {
        ch_preprocessed_fastq_gz = KNEADDATA ( ch_merged_fastq_gz ).preprocessed_fastq_gz
        ch_versions = ch_versions.mix(KNEADDATA.out.versions)
    } else {
        ch_preprocessed_fastq_gz = ch_merged_fastq_gz
    }


    /*-----------------------------------------------------------------------------------
        Taxonomic classification: MetaPhlAn
    -----------------------------------------------------------------------------------*/
    //
    // SUBWORKFLOW: MetaPhlAn
    //
    if ( params.run_metaphlan ) {
        ch_preprocessed_fastq_gz = KNEADDATA ( ch_merged_fastq_gz ).preprocessed_fastq_gz
        ch_versions = ch_versions.mix(KNEADDATA.out.versions)
    } else {
        ch_preprocessed_fastq_gz = ch_merged_fastq_gz
    }

    emit:
    preprocessed_reads_fastq_gz = ch_preprocessed_fastq_gz
    versions                    = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
