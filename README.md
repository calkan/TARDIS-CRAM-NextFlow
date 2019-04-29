# todo : TARDIS with CRAM input
# Tardis

Nextflow wrapper script for [BilkentCompGen/tardis](https://github.com/BilkentCompGen/tardis), runs TARDIS in QUICK MODE. See original [documentation](https://github.com/BilkentCompGen/tardis/blob/master/README.md) for more details.

## Example Command

```bash
nextflow run lifebit-ai/Tardis
--input_folder s3://1000genomes/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam
--ref s3://lifebit-featured-datasets/pipelines/tardis-data/human_g1k_v37.fasta
--sonic s3://lifebit-featured-datasets/pipelines/tardis-data/human_g1k_v37.sonic
--bam_file_prefix NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906
```

`bam_file_prefix` is an optional argument to run TARDIS only on one BAM file if multiple BAMs are present in `input_folder`. All other arguments are mandatory.

## Running on Deploit
Example can be seen by selecting "Try with example data & parameters". Substitute `input_folder` for your own folder containing BAM files. If the BAM was aligned against a different reference genome `ref` and `sonic` parameters will also need to be changed. Sonic files for different reference genomes can be downloaded from [here](https://github.com/BilkentCompGen/sonic-prebuilt) or you can [make your own](https://github.com/calkan/sonic/blob/master/README.md).
![Screen Shot 2018-11-08 at 10.36.22.png](https://images.zenhubusercontent.com/5b5740b66dabc3393a2dcbbb/68e73320-7e7b-4a25-b1e6-e2dd5601a447)

## Output
Output vcf files use the name of the input BAM file(s).
Example output:
![Screen Shot 2018-11-08 at 10.32.58.png](https://images.zenhubusercontent.com/5b5740b66dabc3393a2dcbbb/9fca3458-533a-42b6-b0c2-64c4915ae94a)
