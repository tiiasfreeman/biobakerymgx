/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


//
// SUBWORKFLOWS: Local subworkflows
//
include { FASTQ_READ_PREPROCESSING_KNEADDATA    } from '../../subworkflows/local/fastq_read_preprocessing_kneaddata/main'
include { FASTQ_READ_TAXONOMY_METAPHLAN         } from '../../subworkflows/local/fastq_read_taxonomy_metaphlan/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CAT_FASTQ } from '../../modules/nf-core/cat/fastq/main'


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
        Merge read replicates
    -----------------------------------------------------------------------------------*/
    if ( !params.skip_runmerging ) {

        ch_reads_for_cat_branch = fastq_gz
            .map {
                meta, reads ->
                    def meta_new = meta - meta.subMap('replicate')
                    [ meta_new, reads ]
            }
            .groupTuple()
            .map {
                meta, reads ->
                    [ meta, reads.flatten() ]
            }
            .branch {
                meta, reads ->
                // we can't concatenate files if there is not a second run, we branch
                // here to separate them out, and mix back in after for efficiency
                cat: reads.size() > 2
                skip: true
            }

        ch_reads_runmerged = CAT_FASTQ ( ch_reads_for_cat_branch.cat ).reads
            .mix( ch_reads_for_cat_branch.skip )
            .map {
                meta, reads ->
                [ meta, [ reads ].flatten() ]
            }
        ch_versions = ch_versions.mix(CAT_FASTQ.out.versions)

    } else {
        ch_reads_runmerged = fastq_gz
    }


    /*-----------------------------------------------------------------------------------
        Read-preprocessing: KneadData
    -----------------------------------------------------------------------------------*/
    if ( params.skip_kneaddata ) {
        // create channel from params.kneaddata_db
        if ( !params.kneaddata_db ){
            ch_kneaddata_db = null
        } else {
            ch_kneaddata_db = Channel.value( file( params.kneaddata_db, checkIfExists:true ) )
        }

        //
        // SUBWORKFLOW: KneadData
        //
        ch_preprocessed_fastq_gz = FASTQ_READ_PREPROCESSING_KNEADDATA ( ch_reads_runmerged, ch_kneaddata_db ).preprocessed_fastq_gz
        ch_preprocessed_read_counts_tsv = FASTQ_READ_PREPROCESSING_KNEADDATA.out.read_counts_tsv
        ch_versions = ch_versions.mix(FASTQ_READ_PREPROCESSING_KNEADDATA.out.versions)
    } else {
        ch_preprocessed_fastq_gz = ch_reads_runmerged
        ch_preprocessed_read_counts_tsv = Channel.empty()
    }


    /*-----------------------------------------------------------------------------------
        Taxonomic classification: MetaPhlAn
    -----------------------------------------------------------------------------------*/
    if ( !params.skip_metaphlan ) {
        // create channel from params.kneaddata_db
        if ( !params.metaphlan_db ){
            ch_metaphlan_db = null
        } else {
            ch_metaphlan_db = Channel.value( file( params.metaphlan_db, checkIfExists:true ) )
        }
        // create channel from params.metaphlan_sgb2gtbd_file
        if ( !params.metaphlan_sgb2gtbd_file ){
            ch_metaphlan_sgb2gtbd_file = null
        } else {
            ch_metaphlan_sgb2gtbd_file = Channel.value( file( params.metaphlan_sgb2gtbd_file, checkIfExists:true ) )
        }

        //
        // SUBWORKFLOW: MetaPhlAn
        //
        ch_read_taxonomy_tsv = FASTQ_READ_TAXONOMY_METAPHLAN ( ch_preprocessed_fastq_gz, ch_metaphlan_sgb2gtbd_file, ch_metaphlan_db ).metaphlan_profiles_merged_tsv
        ch_versions = ch_versions.mix(FASTQ_READ_TAXONOMY_METAPHLAN.out.versions)
    } else {
        ch_read_taxonomy_tsv = Channel.empty()
    }

    emit:
    preprocessed_fastq_gz           = ch_preprocessed_fastq_gz
    preprocessed_read_counts_tsv    = ch_preprocessed_read_counts_tsv
    read_taxonomy_tsv               = ch_read_taxonomy_tsv
    versions                        = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
