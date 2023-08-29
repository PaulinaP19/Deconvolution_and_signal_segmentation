// ImageJ macro to batch remove out of nucleus intensities based on DAPI mask
// then deconvolve images using theoretical PSF
// then find foci using 3D Picker
// requires Coloc2 and Iterative 3D deconvolution plugins
// requires the PFS files to be located in the root folder an
// select 2 directory for output

//########################
macro "Batch Coloc" 
	{
	dir1 = getDirectory("Choose Source Directory ");
	dir2 = getDirectory("Choose Results Directory ");
	
	// read in file listing from source directory
	list = getFileList(dir1);
	
	// call the sort function and sort the list
	//sort(list);
	
	// loop over the files in the source directory
	
	setBatchMode(true);
	
	// initialisation
	for (i=0; i<list.length; i++)
		{
		if (endsWith(list[i], ".tif"))
			{
			filename = dir1 + list[i];
			imagename = list[i];		
			open(filename);
			rename("image");
			run("Split Channels");
			selectWindow("C3-image");
			rename("DAPI");
			run("Duplicate...", "duplicate");
			rename("DAPI-2");
			selectWindow("C2-image");
			rename("EdUraw");
			selectWindow("C1-image");
			rename("PCNAraw");
			
			selectWindow("DAPI");
			setAutoThreshold("Otsu dark stack");
			run("Convert to Mask", "method=Otsu background=Dark calculate black");
			run("Options...", "iterations=1 count=1 black do=[Fill Holes] stack");
			run("Options...", "iterations=3 count=1 black do=Dilate stack");
			
			
			
			run("Analyze Particles...", "size=15.00-Infinity display exclude clear summarize add stack");
			
			selectWindow("Results");
			
			run("Close");
						
			
			
				selectWindow("DAPI");
				n=roiManager("count"); 
				for (j = 0; j < n; j++){
					Stack.setSlice(j);
					roiManager("select",j); 
					//roiManager("Delete");
					run("Clear Outside", "slice");
					run("Divide...", "value=255.000 slice");
					
				}
				
							
			
			
			
		
			//Deconvolution
			open(dir1+"PSF_488.tiff");
			rename("PFSgreen");
			
			
			//Deconvolution green
			run("Iterative Deconvolve 3D", "image=[EdUraw] point=PFSgreen output=Deconvolved normalize show log perform detect wiener=0.000 low=1 z_direction=1 maximum=5 terminate=0.010");
			rename("EdU_dec");	
			run("8-bit");	
			run("Set Scale...", "distance=1 known=0.08542 unit=µm");	
			
			imageCalculator("Multiply create stack", "EdU_dec","DAPI");
			rename("EdU_dec_remove");
			
			
			
			// Deconvolution red
			open(dir1+"PSF_561.tiff");
			rename("PFSred");
			
			
			//Deconvolution
			run("Iterative Deconvolve 3D", "image=[PCNAraw] point=PFSred output=Deconvolved normalize show log perform detect wiener=0.000 low=1 z_direction=1 maximum=5 terminate=0.010");
			rename("PCNA_dec");	
			run("8-bit");	
			run("Set Scale...", "distance=1 known=0.08542 unit=µm");	
			
			imageCalculator("Multiply create stack", "PCNA_dec","DAPI");
			rename("PCNA_dec_remove");
			
			
			
			
			
			// Foci counting green
			selectWindow("EdU_dec_remove");
			run("Foci Picker3D", "image=[EdU_dec_remove] background=automatic uniform=1500 automatic=6 minitype=RelativetoMaximum minisetting=0.50 tolerancesetting=20 minimum=8 voxelx=1.000 voxely=1.000 voxelz=1.000 contrast=0 useztolerance=No ztolerance=5 useshapevalidation=No focishaper=6 computingthread=1");
			// save images and results
			
			
			selectWindow("Results");
			n=nResults;
			saveAs("Text", dir2 + imagename + "_" + n +"-EdU_foci.csv");
			run("Close");
			
			selectWindow("FociMask_20.0");
			saveAs("Tiff", dir2 + imagename + "-EdU_foci_mask.tiff");
			close();
			
			
			selectWindow("EdU_dec");
			
			saveAs("Tiff", dir2 + imagename + "-EdU_deconv.tif");
			
			
			
			
			// Foci counting red
			selectWindow("PCNA_dec_remove");
			run("Foci Picker3D", "image=[EdU_dec_remove] background=automatic uniform=1500 automatic=6 minitype=RelativetoMaximum minisetting=0.50 tolerancesetting=20 minimum=8 voxelx=1.000 voxely=1.000 voxelz=1.000 contrast=0 useztolerance=No ztolerance=5 useshapevalidation=No focishaper=6 computingthread=1");
			// save images and results
			
			
			selectWindow("Results");
			m=nResults;
			saveAs("Text", dir2 + imagename + "_" + m +"-PCNA_foci.csv");
			run("Close");
			
			selectWindow("FociMask_20.0");
			saveAs("Tiff", dir2 + imagename + "-PCNA_foci_mask.tiff");
			close();
			
			selectWindow("PCNA_dec");
			
			saveAs("Tiff", dir2 + imagename + "-PCNA_deconv.tif");
			
			selectWindow("Log");
			saveAs("Text", dir2 + imagename + "-foci_description.txt");
			run("Close");
			
			selectWindow("DAPI-2");
			imageCalculator("Multiply create stack", "DAPI-2","DAPI");
			rename("DAPI_clean");
			
			selectWindow("DAPI");
			for (k=1; k<nSlices+1;k++) {
	
			Stack.setSlice(k); 
			setThreshold(1, 255, "raw");
			
			}
			saveAs("Tiff", dir2 + imagename + "-DAPI-mask.tif");
			close();
			
			
			run("Merge Channels...", "c1=PCNA_dec_remove c2=EdU_dec_remove c3=DAPI-2 create");
			saveAs("Tiff", dir2 + imagename + "-deconv.tif");

			close("ROI Manager");
			
			close('*');
			
			
			}
		}
	}


			