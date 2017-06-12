#!/bin/csh
set CONT = 1.5 # minimum contrast not uniform contrast
set currdir = /galveston3/adaptive_vs/freature_list
set nfils = 100 # number of test files
set ntrfils = 50 # number of training files
set dim = 128 # diminsion of images (uniform)


# Running the Adaptive Visual Search observer for every pair of input parameters - smoothing blur and number of iterations for image reconstruction
foreach ITR ( 2 6 )

	foreach BLR (0.000 0.425 0.850 1.274 1.699)
	
		# Creating parameter files - list of files to be evaluated
		
		# Setting the source directories for the image data
		set imgldir = /galveston3/prostate_spect_full_study/data_2d_slices/prostate-study_lesion_1_noise_1_cont_${CONT}_sigma_${BLR}_iter_${ITR}_a1d1/byte
		set imgnldir = /galveston3/prostate_spect_full_study/data_2d_slices/prostate-study_lesion_0_noise_1_cont_nap_sigma_${BLR}_iter_${ITR}_a1d1/byte
		set imgldirnf = /galveston2/prostate_spect_full_study/data_2d_slices/prostate-study_lesion_1_noise_0_cont_${CONT}_sigma_${BLR}_iter_${ITR}_a1d1/byte
		set imgnldirnf = /galveston2/prostate_spect_full_study/data_2d_slices/prostate-study_lesion_0_noise_0_cont_nap_sigma_${BLR}_iter_${ITR}_a1d1/byte

		foreach typ (study train) # Loop for repeating over both training and testing image sets
		      
			  #listing all files to _parfil.txt
			  ls ${imgnldir}/phan_* >! _parfil.txt 
		      ls ${imgnldirnf}/phan_* >> _parfil.txt 
		      ls ${imgldir}/phan_* >> _parfil.txt
		      ls ${imgldirnf}/phan_* >> _parfil.txt

			./comb_cont.csh ${ITR} ${BLR} ${typ} # Varying the lesion contrast
			mv temppar _parfil.txt
	
		      # redistributing files by presence/absence of lesion/noise into temporary files
		      awk '{print($1);}' _parfil.txt | grep -v '_lesion_0' | grep -v '_counts_nan_' >! _tmpfils.txt
		      awk '{print($1);}' _parfil.txt | grep '_lesion_0' | grep -v '_counts_nan_' >! _tmpfilsNo.txt
		      awk '{print($1);}' _parfil.txt | grep -v '_lesion_0' | grep '_counts_nan_' >! _tmpfilsNF.txt
		      awk '{print($1);}' _parfil.txt | grep '_lesion_0' | grep '_counts_nan_' >! _tmpfilsNoNF.txt

		      # Renaming files due to a recent change in location
			  sed 's/galveston2/galveston3/' _tmpfils.txt > _tmpfils2.txt
		      mv _tmpfils2.txt _tmpfils.txt
		      sed 's/galveston2/galveston3/' _tmpfilsNo.txt > _tmpfilsNo2.txt
		      mv _tmpfilsNo2.txt _tmpfilsNo.txt
			  
			  # Getting the lesion coordinate information from the filename
		      sed "s/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/ & /;" _tmpfils.txt | awk '{print($2);}' >! _ord.txt

		      sort _ord.txt >! _ord2.txt; 
			  set locc = `cat _ord2.txt`; 
		      rm -f _fils.txt _filsNo.txt _filsNF.txt _filsNoNF.txt 
			  set t0; set t1
		      foreach lc ( ${locc} )
				set t1 = ( ${t1} 1 )
				set t0 = ( ${t0} 0 )
				grep ${lc} _tmpfils.txt >>! _fils.txt
				grep ${lc} _tmpfilsNo.txt >>! _filsNo.txt
				grep ${lc} _tmpfilsNF.txt >>! _filsNF.txt
				grep ${lc} _tmpfilsNoNF.txt >>! _filsNoNF.txt
		      end
			  
			# Final setup of parameter files - with and without noise  
			cat _filsNo.txt >> _fils.txt
			mv _fils.txt ${typ}parfil
			cat _filsNoNF.txt _filsNoNF.txt >! __tmp
			rm -f _filsNoNF.txt
			mv __tmp ${typ}parfil_nf
		end
		
		# Creating the template image
		./getAvgTgt_ms.csh trainparfil ${dim} b

		# Remving feature files if prexisting
		cd currdir
		set c = 1
		while ( -f featset_$c )
			rm featset_$c
			@ c ++
		end 
		
		# Running the Adaptive VS observer on IDL
		echo ".run mk_feat_list.pro" >! _tmptest.pro
		echo "mk_feat_list, 'trainparfil', ${ntrfils}, ${dim}" >> _tmptest.pro
		echo ".run training.pro" >> _tmptest.pro
		echo "training, 'trainparfil', ${ntrfils}, ${dim}" >> _tmptest.pro
		echo ".run testing.pro" >> _tmptest.pro
		echo "testing, 'studyparfil', ${nfils}, ${dim}" >> _tmptest.pro
		idl < _tmptest.pro

		# Performance evaluation
		set c = 1
		rm -f lroc_indiv.txt
		while ( -f featset_$c )
			./empiricalLROC -i featset_$c -rcl 5 -x >>! lroc_indiv.txt
			@ c ++
		end 

		echo ".run avg_lroc.pro" >! _tmptest.pro
		echo "avg_lroc, 'lroc_indiv.txt' " >> _tmptest.pro

		idl < _tmptest.pro
		set lroc_final = `awk '{print($1);}' lroc_temp`
		
        # Printing final output
		echo $ITR $BLR $lroc_final >>! lroc_areas.txt

	end

end
#rm -f lroctemp

