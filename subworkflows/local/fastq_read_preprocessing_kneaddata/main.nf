include { KNEADDATA_DATABASE            } from '../../modules/local/kneaddata/database/main'
include { KNEADDATA_KNEADDATA           } from '../../modules/local/kneaddata/kneaddata/main'
include { KNEADDATA_READCOUNTS          } from '../../modules/local/kneaddata/readcounts/main'

workflow FASTQ_READ_PREPROCESSING_KNEADDATA {

    take:
    ch_raw_reads_fastq_gz   // channel: [ val(meta), [ reads_1.fastq.gz, reads_2.fastq.gz ] ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Download KneadData database
    //
    ch_kneaddata_db = KNEADDATA_DATABASE ().kneaddata_db
    ch_versions = ch_versions.mix(KNEADDATA_DATABASE.out.versions)

    //
    // MODULE: Trim and remove human reads
    //
    ch_preprocessed_reads_fastq_gz = KNEADDATA_KNEADDATA ( ch_raw_short_reads, ch_kneaddata_db ).preprocessed_reads
    ch_versions = ch_versions.mix(KNEADDATA_KNEADDATA.out.versions)

    emit:
    reads = KNEADDATA_KNEADDATA.out.reads // channel: [ val(meta), [ reads ] ]

    versions = ch_versions // channel: [ versions.yml ]
}
