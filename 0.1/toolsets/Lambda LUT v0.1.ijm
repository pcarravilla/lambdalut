/* 
 *  ----------------------------------------------------------------------------------
 *  Author: Pablo Carravilla
 *  
 *  Name: Spectral Lambda
 *  Version: 0.1
 *  Date: 27-11-2024
 *  
 *  Description: 
 *  This macro takes a multichannel spectral image labelled with emission wavelengths
 *  and creates an RGB image with colours from the RGB rainbow lut assigned to their  
 *  respective channel.
 *    
 *  Copyright (c) [2024] [Pablo Carravilla]
 *  
 *  License: GNU General Public License v3.0
 *  For more information, please refer to the LICENSE file provided with this project.
 *  
 *  ----------------------------------------------------------------------------------
 */



// This macro creates a spectral image with colours corresponding to the emission wavelength


macro "Lambda LUT v0.1 Action Tool - icon:lambda.png" {
	
	setBatchMode(true);
	version = 0.1;
	
	print(" \n"
		+ "Running Lambda LUT " + version);
	
	// Duplicate raw image to avoid data loss
	rawDataID = getImageID();
	title = getTitle();
	run("Duplicate...", "title=dat duplicate");
	dataID = getImageID();
	
	// Get channel labels 
	rawLabels = getChannelLabels(dataID);
	
	// Remove NaN labels, i.e. non-spectral channels
	removeNonSpectralChannels(dataID, rawLabels);
	
	labels = getChannelLabels(dataID);
	
	missingChannels = determineMissingChannels(labels);
	
	addMissingChannels(dataID, missingChannels);
	
	
	createLambdaImage(dataID);
	
	setBatchMode("exit and display");
	
	print("Finished running Lambda LUT");
	
	
	
	
	////////////////////////////////////////	FUNCTIONS	////////////////////////////////////////
	
	
		function getChannelLabels(dataImg) { 
		// Returns the channel labels as array of numbers
		
			selectImage(dataImg);
			getDimensions(width, height, channels, slices, frames);
			
			wavelengthArray = newArray(channels);
			
			// Get channel labels
			for (c = 1; c <= channels; c++) {
					Stack.setChannel(c);
					label = getInfo("slice.label");
					
					// Convert to number
					wavelength = parseInt(label);
									
					// Store
					wavelengthArray[c - 1] = wavelength;
			}
		
			return wavelengthArray;
			
		}
		
		
		
		
		
		function removeNonSpectralChannels(dataImg, wavelengthArray) {
		// Remove channels that do not have a wavelength label (NaN label)
					
			selectImage(dataImg);
			getDimensions(width, height, channels, slices, frames);
			
			r = 1; // This variable accounts for the channel number changing upon slice deletion
			
			for (c = 1; c <= channels; c++) {
	
				
				// Remove slice is label is NaN
				if (isNaN(wavelengthArray[c-1])) {
					
					Stack.setChannel(r);
					label = getInfo("slice.label");
					
					// Warn the user
					print("The label for channel " + c + " is " + label);
					print("It will be excluded since it is not a number.");
					
					// Delete channel
					run("Delete Slice", "delete=channel");
					
					r = r - 1; // To account for the channel number being lower since this one was deleted
				}
				
				r++;
			}
			
			//
		}
		
		
		
		
		function determineMissingChannels(wavelengthArray) { 
		// Finds the range of emission wavelengths and determines the missing ones (400 - 700 nm)
			
			// Find array length, i.e. number of channels
			channelNumber = wavelengthArray.length;
			
			// Find first and last values 
			firstWavelength = wavelengthArray[0];
			lastWavelength = wavelengthArray[channelNumber-1];
			
			// Calculate wavelength range and step size
			range = lastWavelength - firstWavelength;
			step = range / (channelNumber - 1);
	
			// Determine number of channels to add
			blueMissingRange = firstWavelength - 400; // LUT starts from 400 nm
			redMissingRange = 700 - lastWavelength; // LUT ends at 700 nm
			
			blueMissingSteps = round(blueMissingRange / step);
			redMissingSteps = round(redMissingRange / step);
			
			missingChannelsArray = newArray(blueMissingSteps, redMissingSteps);
			
			return missingChannelsArray;
	
		}
		
		
		
		
		
		function addMissingChannels(dataImg, missingChannelArray) { 
		// Adds empty slices to make the channel range 400-700 nm
			selectImage(dataImg);
			
			blueMissingChannels = missingChannelArray[0];
			redMissingChannels = missingChannelArray[1];
			
			// Add blue channels
			for (c = 1; c <= blueMissingChannels; c++) {
				
				run("Add Slice", "add=channel prepend");
			}
			
			// Add red channels
			for (c = 1; c <= redMissingChannels; c++) {
				
				run("Add Slice", "add=channel");
			}
			
		}
		
		
		
		
		
		function createLambdaImage(dataImg) { 
		// Creates a colour-coded image according to the emission wavelength
			
			// Converts channels to frames
			// This is necessary because the function only works with time experiments
			
			run("Re-order Hyperstack ...", "channels=[Frames (t)] slices=[Slices (z)] frames=[Channels (c)]");
			reorderedImg = getImageID();
			
			selectImage(reorderedImg);
			depth = bitDepth();
			maxVal = pow(2, depth) - 1;
			getDimensions(width, height, channels, slices, frames);
			for (f = 1; f <= frames; f++) {
				Stack.setFrame(f);
				setMinAndMax(0, maxVal);
			}
	
			
			// Colour code with the visible.lut
			selectImage(reorderedImg);
			setBatchMode("exit and display");
			run("Temporal-Color Code", "lut=[Rainbow RGB]] start=1 end=frames");
			rename("Spectral_" + title);
			run("Enhance Contrast", "saturated=0.35");
			
			
			selectImage(reorderedImg);
			close();
	
		}
	
}