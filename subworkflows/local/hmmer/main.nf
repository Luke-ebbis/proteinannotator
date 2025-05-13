// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { HMMER_HMMPRESS } from '../modules/nf-core/hmmer/hmmpress/main'
include { HMMER_HMMSEARCH } from '../modules/nf-core/hmmer/hmmsearch/main'


workflow HMMER_ANNOTATION {
    take:
    ch_proteins     // channel: [ val(meta), path(fasta) ]
    ch_hmm_db      // channel: [ val(meta), path(hmm) ]
    
    main:
    ch_versions = Channel.empty()
    
    //
    // MODULE: Prepare HMM database with hmmpress
    //
    HMMER_HMMPRESS (
        ch_hmm_db
    )
    
    //
    // MODULE: Run HMMER hmmsearch
    //
    HMMER_HMMSEARCH (
        ch_proteins,
        HMMER_HMMPRESS.out.hmm,
        true,  // write_align
        true,  // write_target
        true   // write_domain
    )
    
    ch_versions = ch_versions.mix(HMMER_HMMPRESS.out.versions)
    ch_versions = ch_versions.mix(HMMER_HMMSEARCH.out.versions)
    
    emit:
    pressed_db      = HMMER_HMMPRESS.out.hmm              // channel: [ val(meta), path(hmm) ]
    search_results  = HMMER_HMMSEARCH.out.output          // channel: [ val(meta), path(txt) ]
    domtblout       = HMMER_HMMSEARCH.out.domtblout      // channel: [ val(meta), path(domtblout) ]
    target_summary  = HMMER_HMMSEARCH.out.target_summary  // channel: [ val(meta), path(tblout) ]
    domain_alignments = HMMER_HMMSEARCH.out.domain_alignments // channel: [ val(meta), path(sto) ]
    versions        = ch_versions                        // channel: [ versions.yml ]
}