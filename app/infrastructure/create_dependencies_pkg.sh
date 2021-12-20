#!/bin/bash

cd $path_cwd
dir_name="sentiment-analysis-pkg"
mkdir $dir_name

# Create and activate virtual environment...
virtualenv -p $runtime env_sentiment_analysis
source $path_cwd/env_sentiment_analysis/bin/activate

# Installing python dependencies...
FILE=$path_cwd/sentiment-analysis/requirements.txt

if [ -f "$FILE" ]; then
  echo "Installing dependencies..."
  echo "From: requirements.txt file exists..."
  pip install -r "$FILE" --no-cache-dir

else
  echo "Error: requirements.txt does not exist!"
  exit
fi

# Deactivate virtual environment...
deactivate

# Create deployment package...
echo "Creating deployment package..."
cd env_sentiment_analysis/lib/$runtime/site-packages/
cp -r . $path_cwd/$dir_name
cp $path_cwd/sentiment-analysis/sentiment-analysis.py $path_cwd/$dir_name

# Removing virtual environment folder...
echo "Removing virtual environment folder..."
rm -rf $path_cwd/env_sentiment_analysis

echo "Finished script execution!"
