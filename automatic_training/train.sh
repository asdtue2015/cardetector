#!/bin/bash
STEPS=24
BATCH_SIZE=300
MASTER_DIR="$HOME/Projects/TUE_Multiclass_Detector"
LOCAL_DIR=$(pwd)/..

# matlab path
MATLAB=~/MATLAB/R2015b/bin/matlab

# recreate the structure
(cd $LOCAL_DIR;\
 rm -r data;\
 mkdir data;\
 cd data;\
 mkdir hog_2;\
 mkdir image_2;\
 mkdir label_2;\
 mkdir nclabel_2;
 cp $MASTER_DIR/data/negative_features.mat ./negative_features.mat
 ln $MASTER_DIR/data/positive_features.mat ./positive_features.mat
 cp $MASTER_DIR/data/carDetector56x48.yml ./carDetector56x48.yml
 )

# compile the detector
(cd "$LOCAL_DIR/src/detector"; rm CMakeCache.txt; rm -r CMakeFiles; rm detector; cmake .; make)

for i in `seq 0 $STEPS`;
do	# every step

	# backup the classifier
	(cp ../data/carDetector56x48.yml ./carDetector56x48.yml.backup$i)

	# create hard links to the files
	k=0 # files are renamed starting at 0 every time because the matlab script needs this...
	for j in `seq $[$i*$BATCH_SIZE] $[$[$i+1]*$BATCH_SIZE-1]`;
	do
		ln $MASTER_DIR/data/image_2/$(printf "%06d" $j).png $LOCAL_DIR/data/image_2/$(printf "%06d" $k).png
		ln $MASTER_DIR/data/label_2/$(printf "%06d" $j).txt $LOCAL_DIR/data/label_2/$(printf "%06d" $k).txt
		ln $MASTER_DIR/data/hog_2/$(printf "%06d" $j).yml $LOCAL_DIR/data/hog_2/$(printf "%06d" $k).yml
		k=$[$k+1]
	done

	# run the detector
	(cd "$LOCAL_DIR/src/detector"; ./detector --scale 1.12 --nlevels 13 --gr_threshold 0 --hit_threshold 0 $LOCAL_DIR/data/image_2 --write_file)
	find $LOCAL_DIR/src/detector -name "*.txt" -exec mv -i -t $LOCAL_DIR/data/nclabel_2 {} +;

	# count the number of hard negatives
#	(cd $LOCAL_DIR/data/nclabel_2; find . | xargs wc -l)

	# perform hard negative mining
	# concat to existing negative HOG features
	# train the classifier
	(cd $LOCAL_DIR/matlab/automatic; $MATLAB -nodesktop -nosplash -nojvm < ngmining_training.m)
		# FIXME change call to have a quit, like: matlab -nodesktop -nodisplay -r "cd folder2/; run('mycode.m'); quit"  < /dev/null  > output.txt

	# clean images and labels
	ls $LOCAL_DIR
	rm $LOCAL_DIR/data/hog_2/*.yml
	rm $LOCAL_DIR/data/image_2/*.png
	rm $LOCAL_DIR/data/label_2/*.txt
	rm $LOCAL_DIR/data/nclabel_2/*.txt
done
