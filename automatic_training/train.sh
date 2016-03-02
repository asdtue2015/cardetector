#!/bin/bash
STEPS=3
BATCH_SIZE=20
IMAGE_DIR="$HOME/Projects/TUE_Multiclass_Detector/data/image_2"
DETECTOR_DIR="$HOME/asd2015dev/autotrain/src/detector"
LOCAL_DIR=$(pwd)

# compile the detector
(cd "$DETECTOR_DIR"; )

for i in `seq 0 $STEPS`;
do	# every step

	# backup the classifier

	# create hard links to the files
	k=0 # files are renamed starting at 0 every time because the matlab script needs this...
	for j in `seq $[$i*$BATCH_SIZE] $[$[$i+1]*$BATCH_SIZE-1]`;
	do
		ln $IMAGE_DIR/$(printf "%06d" $j).png $(printf "%06d" $k).png
		k=$[$k+1]
	done

	# run the detector
	(cd "$DETECTOR_DIR"; ./detector --scale 1.12 --nlevels 13 --gr_threshold 0 --hit_threshold 0 $LOCAL_DIR --write_file)
	find $DETECTOR_DIR -name "*.txt" -exec mv -i -t $LOCAL_DIR {} +;

	# perform hard negative mining
	# concat to existing negative HOG features

	# backup the negative HOG features

	# train the classifier

	# clean images and labels
	ls $LOCAL_DIR
	rm *.png
	rm *.txt

done
