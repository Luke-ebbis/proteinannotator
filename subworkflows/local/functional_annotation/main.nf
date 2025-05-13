//
// Functional annotation of protein sequences
//
include { HMMER } from '../hmmer/main'

workflow FUNCTIONAL_ANNOTATION {
    // TODO nf-core: substitute modules here for the modules of your subworkflow
    take:
    ch_fasta // channel: [ val(meta), [ fasta ] ]

    main:

    ch_versions = Channel.empty()

    // SUBWORKFLOW: HMMER domain annotation
    //
    if (params.run_hmmer && params.hmm_db) {
        // Prepare HMM database channel
        ch_hmm_db = Channel
            .fromPath(params.hmm_db, checkIfExists: true)
            .map { hmm ->
                def meta = [:]
                meta.id = hmm.baseName
                [ meta, hmm ]
            }
        HMMER (
            ch_proteins,
            ch_hmm_db
        )
        ch_versions = ch_versions.mix(HMMER.out.versions)
    }
    // TODO: Add other annotation tools in the future
    emit:
    hmmer_domtblout      = params.run_hmmer ? HMMER.out.domtblout : Channel.empty()
    hmmer_results        = params.run_hmmer ? HMMER.out.search_results : Channel.empty()
    hmmer_target_summary = params.run_hmmer ? HMMER.out.target_summary : Channel.empty()
    hmmer_alignments     = params.run_hmmer ? HMMER.out.domain_alignments : Channel.empty()
    versions             = ch_versions
}

