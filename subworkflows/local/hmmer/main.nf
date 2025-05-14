// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { HMMER_HMMPRESS } from '../../../modules/nf-core/hmmer/hmmpress/main'
include { HMMER_HMMSEARCH } from '../../../modules/nf-core/hmmer/hmmsearch/main'

process DECOMPRESS_HMM {
    tag "$meta.id"
    input:
    tuple val(meta), path(file_in)
    output:
    tuple val(meta), path("*.hmm"), emit: decompressed
    script:
    def file_out = file_in.baseName
    """
    if [[ ${file_in} == *.gz ]]; then
        gunzip -c ${file_in} > ${file_out}
    else
        ln -s ${file_in} ${file_out}
    fi
    """
}
process DECOMPRESS_PROTEINS {
    tag "$meta.id"
    input:
    tuple val(meta), path(file_in)
    output:
    tuple val(meta), path("*.{fasta,fna,fa,faa}"), emit: decompressed
    script:
    def file_out = file_in.baseName
    """
    if [[ ${file_in} == *.gz ]]; then
        gunzip -c ${file_in} > ${file_out}
    else
        ln -s ${file_in} ${file_out}
    fi
    """
}

workflow HMMER_ANNOTATION {
    take:
    ch_proteins     // channel: [ val(meta), path(fasta) ]
    ch_hmm_db      // channel: [ val(meta), path(hmm) ]
    main:
    ch_versions = Channel.empty()
    //
    // Decompress HMM files if needed

    // Process HMM files
    DECOMPRESS_HMM(ch_hmm_db)
    ch_hmm_ready = DECOMPRESS_HMM.out.decompressed
    // Process protein files
    DECOMPRESS_PROTEINS(ch_proteins)
    ch_proteins_ready = DECOMPRESS_PROTEINS.out.decompressed
    // MODULE: Prepare HMM database with hmmpress

    HMMER_HMMPRESS (
        ch_hmm_ready
    )
    //
    // MODULE: Run HMMER hmmsearch
    //
    ch_hmmsearch_input = ch_proteins_ready
        .combine(ch_hmm_ready)
        .map { protein_meta, fasta, hmm_meta, hmm ->
            // Use protein meta for the output, hmm first, then sequences
            [ protein_meta, hmm, fasta, true, true, true ]
        }
    //
    HMMER_HMMSEARCH (
        ch_hmmsearch_input
    )
    ch_versions = ch_versions.mix(HMMER_HMMPRESS.out.versions)
    ch_versions = ch_versions.mix(HMMER_HMMSEARCH.out.versions)
    emit:
    pressed_db      = HMMER_HMMPRESS.out.compressed_db              // channel: [ val(meta), path(hmm) ]
    txt_output  = HMMER_HMMSEARCH.out.output          // channel: [ val(meta), path(txt) ]
    domain_summary       = HMMER_HMMSEARCH.out.domain_summary      // channel: [ val(meta), path(domtblout) ]
    target_summary  = HMMER_HMMSEARCH.out.target_summary  // channel: [ val(meta), path(tblout) ]
    alignments = HMMER_HMMSEARCH.out.alignments // channel: [ val(meta), path(sto) ]
    versions        = ch_versions                        // channel: [ versions.yml ]
}
