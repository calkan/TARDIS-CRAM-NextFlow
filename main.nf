#!/usr/bin/env nextflow

/*
 * SET UP CONFIGURATION VARIABLES
 */
bam = Channel
    .fromPath("${params.input_folder}/${params.bam_file_prefix}.bam")
    .ifEmpty { exit 1, "${params.input_folder}/${params.bam_file_prefix}.bam not found.\nPlease specify --input_folder option (--input_folder bamfolder)"}
    .map { bam -> tuple(bam.simpleName, bam) }

if (params.get_bai) {
bai = Channel
    .fromPath("${params.input_folder}/${params.bam_file_prefix}*.bai")
    .ifEmpty { exit 1, "${params.input_folder}/${params.bam_file_prefix}*.bai not found.\nPlease specify ensure that your BAM index(es) are in your input_folder"}
    .map { bai -> tuple(bai.simpleName, bai) }

completeChannel = bam.combine(bai, by: 0)
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
summary['Bam file']         = "${params.input_folder}/${params.bam_file_prefix}*.bam"
summary['Bam index file']   = "${params.input_folder}/${params.bam_file_prefix}*.bam.bai"
summary['Sonic file']       = params.sonic
summary['Reference genome'] = params.ref
summary['Output dir']       = params.outdir
summary['Working dir']      = workflow.workDir
log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
log.info "========================================="

if (!params.get_bai) {
  process preprocess_bam{

  tag "${bam}"
	container 'lifebitai/samtools'

  input:
  set val(name), file(bam) from bam

  output:
  set val(name), file("ready/${bam}"), file("ready/${bam}.bai") into completeChannel

  script:
  """
  mkdir ready
  [[ `samtools view -H ${bam} | grep '@RG' | wc -l`   > 0 ]] && { mv $bam ready;}|| { picard AddOrReplaceReadGroups \
  I=${bam} \
  O=ready/${bam} \
  RGID=${params.rgid} \
  RGLB=${params.rglb} \
  RGPL=${params.rgpl} \
  RGPU=${params.rgpu} \
  RGSM=${params.rgsm};}
  cd ready ;samtools index ${bam};
  """
  }
}



process tardis {
  tag "$bam_name"
	publishDir "${params.outdir}", mode: 'copy'

	input:
  set val(bam_name), file(bam), file(bai) from completeChannel
	file ref from ref
	file sonic from sonic

	output:
	file('*') into results

	script:
	"""
  tardis \
  --input $bam \
  --ref $ref \
  --sonic $sonic \
  --output $bam_name ${extraflags}
	"""
}

workflow.onComplete {
	println ( workflow.success ? "\nTARDIS is done!" : "Oops .. something went wrong" )
}