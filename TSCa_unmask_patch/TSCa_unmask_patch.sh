#!/bin/bash
# change <sample>.variables file and bash within sample folder

Version=5
        #load sample variables
        . *.variables

        #make sample-specific bed files
        if [ ${#SampleProjects[@]} -eq 0 ]; then

                echo "Whole panel analysis for $SampleID"

                #no targets specified; use whole panel
                cp /data/diagnostics/pipelines/IlluminaTruSightCancer/"$Version"/IlluminaTruSightCancer_Design.bed "$RunID"_"$SampleID"_Targets.bed

        else

            	#targets provided in the samplesheet
                for Target in "${SampleProjects[@]}"; do
                        echo "$Target for $SampleID"
                        cat /data/diagnostics/pipelines/IlluminaTruSightCancer/"$Version"/beds/"$Target".bed >> "$RunID"_"$SampleID"_Targets.bed
                done

        fi

	#extract on-target variants for this sample
        /usr/java/jdk1.7.0_51/bin/java -Xmx2g -jar /share/apps/GATK-distros/GATK_3.4-46/GenomeAnalysisTK.jar \
        -R /data/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
        -T SelectVariants \
        -o "$RunID"_"$SampleID"_Variants_Targets.vcf \
        -V ../"$RunID"_Variants_Filtered_Classified.vcf \
        -L "$RunID"_"$SampleID"_Targets.bed \
        --excludeNonVariants \
        -sn "$SampleID" \
        -dt NONE

        #write variant report
        /usr/java/jdk1.7.0_51/bin/java -jar /data/diagnostics/apps/VariantReporter.jar \
        "$RunID"_"$SampleID"_Variants_Targets.vcf \
        ../"$RunID"_VEP.txt \
        /data/diagnostics/pipelines/IlluminaTruSightCancer/"$Version"/IlluminaTruSightCancer_PreferredTranscripts.txt

        #identify callable loci
        /usr/java/jdk1.7.0_51/bin/java -Xmx2g -jar /share/apps/GATK-distros/GATK_3.4-46/GenomeAnalysisTK.jar \
        -T CallableLoci \
        -R /data/db/human/gatk/2.8/b37/human_g1k_v37.fasta \
        -I "$RunID"_"$SampleID".bam \
        -L "$RunID"_"$SampleID"_Targets.bed \
        -summary "$RunID"_"$SampleID"_callableloci.txt \
        -o "$RunID"_"$SampleID"_callable_status.bed \
        --minDepth 30 \
        --minMappingQuality 20 \
        --minBaseQuality 20 \
        -dt NONE

        #select non-passing regions
        grep -v CALLABLE "$RunID"_"$SampleID"_callable_status.bed | cut -s -f1,2,3 > "$SampleID"_Targets_Gaps.bed

        #annotate gaps with HGVS & gene
        perl /data/diagnostics/scripts/bed2vcf.pl "$SampleID"_Targets_Gaps.bed > "$SampleID"_Targets_Gaps.vcf

        #annotate gap VCF
        perl /share/apps/vep-distros/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl \
        -i "$SampleID"_Targets_Gaps.vcf \
        --fasta /share/apps/vep-distros/ensembl-tools-release-75/scripts/variant_effect_predictor/annotations/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa \
        --dir /share/apps/vep-distros/ensembl-tools-release-75/scripts/variant_effect_predictor/annotations \
        --output "$SampleID"_Targets_Gaps_VEP.txt \
        --refseq \
        --offline \
        --force_overwrite \
        --no_stats \
        --sift b \
        --polyphen b \
        --numbers \
        --hgvs \
        --symbol \
        --gmaf \
        --maf_1kg \
        --maf_esp \
        --fields Uploaded_variation,Location,Allele,AFR_MAF,AMR_MAF,ASN_MAF,EUR_MAF,AA_MAF,EA_MAF,Consequence,SYMBOL,Feature,HGVSc,HGVSp,PolyPhen,SIFT,EXON,INTRON

        #convert back to BED format
        /usr/java/jdk1.7.0_51/bin/java -jar /data/diagnostics/apps/RegionAnnotator.jar "$SampleID"_Targets_Gaps.bed "$SampleID"_Targets_Gaps_VEP.txt /data/diagnostics/pipelines/IlluminaTruSightCancer/"$Version"/IlluminaTruSightCancer_PreferredTranscripts.txt

        #clean up
        rm "$RunID"_"$SampleID"_callable_status.bed
        rm "$SampleID"_Targets_Gaps.bed
        rm "$SampleID"_Targets_Gaps.vcf
        rm "$SampleID"_Targets_Gaps_VEP.txt


