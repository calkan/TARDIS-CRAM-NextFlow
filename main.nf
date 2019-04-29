#!/usr/bin/env nextflow

/*
 * SET UP CONFIGURATION VARIABLES
 */
cram = Channel
    .fromPath("${params.input_folder}/${params.cram_file_prefix}.cram")
    .ifEmpty { exit 1, "${params.input_folder}/${params.cram_file_prefix}.cram not found.\nPlease specify --input_folder option (--input_folder cramfolder)"}
    .map { cram -> tuple(cram.simpleName, cram) }

if (params.get_crai) {
crai = Channel
    .fromPath("${params.input_folder}/${params.cram_file_prefix}*.crai")
    .ifEmpty { exit 1, "${params.input_folder}/${params.cram_file_prefix}*.crai not found.\nPlease specify ensure that your cram index(es) are in your input_folder"}
    .map { crai -> tuple(crai.simpleName, crai) }

completeChannel = cram.combine(crai, by: 0)
}

ref = Channel
		.fromPath(params.ref)
		.ifEmpty { exit 1, "${params.ref} not found.\nPlease specify --ref option (--ref fastafile)"}

sonic = Channel
    .fromPath(params.sonic)
    .ifEmpty { exit 1, "${params.sonic} not found.\nPlease specify --sonic option (--sonic sonicfile)"}

extraflags = ""
extraflags += params.rp ? " --rp $params.rp" : ""
extraflags += params.first_chr ? " --first-chr $params.first_chr" : ""
extraflags += params.last_chr ? " --last-chr $params.last_ch" : ""

// Header log info
log.info """=======================================================
		TARDIS
======================================================="""
def summary = [:]
summary['Pipeline Name']    = 'TARDIS'
summary['cram file']         = "${params.input_folder}/${params.cram_file_prefix}*.cram"
summary['cram index file']   = "${params.input_folder}/${params.cram_file_prefix}*.cram.crai"
summary['Sonic file']       = params.sonic
summary['Reference genome'] = params.ref
summary['Output dir']       = params.outdir
summary['Working dir']      = workflow.workDir
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

if (!params.get_crai) {
  process preprocess_cram{

  tag "${cram}"
	container 'lifebitai/samtools'

  input:
  set val(name), file(cram) from cram

  output:
  set val(name), file("ready/${cram}"), file("ready/${cram}.crai") into completeChannel

  script:
  """
  mkdir ready
  [[ `samtools view -H ${cram} | grep '@RG' | wc -l`   > 0 ]] && { mv $cram ready;}|| { picard AddOrReplaceReadGroups \
  I=${cram} \
  O=ready/${cram} \
  RGID=${params.rgid} \
  RGLB=${params.rglb} \
  RGPL=${params.rgpl} \
  RGPU=${params.rgpu} \
  RGSM=${params.rgsm};}
  cd ready ;samtools index ${cram};
  """
  }
}



process tardis {
  tag "$cram_name"
	publishDir "${params.outdir}", mode: 'copy'

	input:
  set val(cram_name), file(cram), file(crai) from completeChannel
	file ref from ref
	file sonic from sonic

	output:
	file('*') into results

	script:
	"""
  tardis \
  --input $cram \
  --ref $ref \
  --sonic $sonic \
  --output $cram_name ${extraflags}
	"""
}

workflow.onComplete {
	println ( workflow.success ? "\nTARDIS is done!" : "Oops .. something went wrong" )
}
