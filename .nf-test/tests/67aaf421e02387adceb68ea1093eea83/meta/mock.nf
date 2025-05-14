import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test workflow
include { HMMER_ANNOTATION } from '/Users/saba.nafees/code/nextflow/proteinannotator/subworkflows/local/hmmer/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()

def jsonWorkflowOutput = new JsonGenerator.Options().excludeNulls().build()

workflow {

    // run dependencies
    

    // workflow mapping
    def input = []
    
                // Create test protein channel
                input[0] = Channel.of(
                    [
                        [ id:'test_protein' ],
                        file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/delete_me/hmmer/e_coli_k12_16s.fna.gz", checkIfExists: true)
                    ]
                )
                // Create test HMM database channel (unpressed)
                input[1] = Channel.of(
                    [
                        [ id:'test_hmm' ],
                        file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/delete_me/hmmer/bac.16S_rRNA.hmm.gz", checkIfExists: true)
                    ]
                )
                
    //----

    //run workflow
    HMMER_ANNOTATION(*input)
    
    if (HMMER_ANNOTATION.output){

        // consumes all named output channels and stores items in a json file
        for (def name in HMMER_ANNOTATION.out.getNames()) {
            serializeChannel(name, HMMER_ANNOTATION.out.getProperty(name), jsonOutput)
        }	  
    
        // consumes all unnamed output channels and stores items in a json file
        def array = HMMER_ANNOTATION.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
}


def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonWorkflowOutput.toJson(result)
    
}
