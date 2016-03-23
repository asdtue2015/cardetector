This read me file is for the detection stand alone component.
**************************************************************

Based on the classifiers relative path and color code provided in the clasifiers.txt file. 
The detection component will detect the objects and display them in rectangular boxes with the respecting colors corresponding to the classifier/s.
Check in the detector file the handle key function to determine the run time changeable parameters. 
Check the read function to know the flags supported by this component.
Refer to the documentation for more information.

*****************************************************************************************************************************************************************************************************
To run the component:

cmake .

make

./detector RelativePathOfTheImage/sSource --DesiredFlags




