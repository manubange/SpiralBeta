# Matlab Code for the SpiralBeta paper.  
The function determineThresh.m defines the beta amplitude threshold (defined as 75 percentile of the amplitude distribution).  
The function betaBurstFeatures.m extracts burst amplitude, duration, and number of bursts of a given segment of electrophysiological data.    
Example data are provided in /data  

# Installation guide
No installation required. 
Download FieldTrip36 (https://www.fieldtriptoolbox.org/) and add the folder to the working directory in Matlab. If Fieldtrip cannot be downloaded, the example scripts will skip the related steps and load already prepocessed data instead.
Kinematics toolbox is attached (http://www.diedrichsenlab.org/toolboxes/toolbox_kinematics.htm)


# Demo Instructions
To run the demo, open the example scripts (main_spiral.m and main_determineBetaBurstsPatxx.m) in the matlab editor and press f5 to run all sections.
main_spiral.m loads a spiral drawn by a studyparticipant (Spiral_patxx.mat), healthy person (Spiral_HC.mat), or a modelled spiral.  
main_determineBetaBurstsPatxx.m calculates burst characteristics of one example dataset (LFP_patxx.mat).  
main_determineBetaBursts.m loads 10 seconds of modelled electrophysiological data (LFP.mat).  


Expected time to run:  
- spiral.m < 1 minute
- determine_BetaBurstsPatxx.m < 1 minute   
- determine_BetaBursts.m < 1 minute   

Expected output can be seen in   
- SpiralPatxx.jpg, SpiralHC.jpg, and SpiralModel.jpg  
- PowerspecRest-Draw.jpg and Powerspec.jpg  
- BetaBurstDrawing.jpg and BetaBurstDetermination.jpg  


# System requirements
Dependencies:
- FieldTrip36 (version 20220310, https://www.fieldtriptoolbox.org/) 
- Kinematics toolbox (http://www.diedrichsenlab.org/toolboxes/toolbox_kinematics.htm, attached)


Tested with Matlab 9.11.0.1769968 (R2021b) and Fieldtrip36 (20220310) on a Centos7 (CentOS Linux release 7.9.2009 (Core)) Server and   
Matlab 9.13.0.2049777 (R2022b) and Fieldtrip36 (20220310) on a Windows10 home desktop PC.
