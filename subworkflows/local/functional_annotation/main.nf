include { UNIFIRE                } from '../../../modules/local/unifire/main'


workflow FUNCTIONAL_ANNOTATION {

    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]

    main:

    ch_versions = Channel.empty()

    UNIFIRE ( ch_fasta )

    ch_versions = ch_versions.mix( UNIFIRE.out.versions )

    // TODO nf-core: substitute modules here for the modules of your subworkflow

    emit:
    unifire_arba    = UNIFIRE.out.arba
    unifire_unirule = UNIFIRE.out.unirule
    unifire_pirsr   = UNIFIRE.out.pirsr
    versions        = ch_versions                     // channel: [ versions.yml ]
}

