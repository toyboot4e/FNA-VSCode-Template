#!/bin/bash
# Program: getFNA
# Author: Caleb Cornett
# Usage: ./getFNA.sh
# Description: Quick and easy way to install a local copy of FNA and its native libraries.

# Checks if git is installed
function checkGit()
{
    git --version > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
        echo >&2 "ERROR: Git is not installed. Please install git to download FNA."
        exit 1
    fi
}

# Clones FNA from the git master branch
function downloadFNA()
{
    checkGit
	echo "Downloading FNA..."
	git -C $MY_DIR clone https://github.com/FNA-XNA/FNA.git --recursive
	if [ $? -eq 0 ]; then
		echo "Finished downloading!"
	else
		echo >&2 "ERROR: Unable to download successfully. Maybe try again later?"
	fi
}

# Pulls FNA from the git master branch
function updateFNA()
{
    checkGit
    echo "Updating to the latest git version of FNA..."
	git -C "$MY_DIR/FNA" pull --recurse-submodules
	if [ $? -eq 0 ]; then
		echo "Finished updating!"
	else
		echo >&2 "ERROR: Unable to update."
		exit 1
	fi
}

# Downloads and extracts prepackaged archive of native libraries ("fnalibs")
function getLibs()
{
    # Downloading
    echo "Downloading latest fnalibs..."
    curl http://fna.flibitijibibo.com/archive/fnalibs.tar.bz2 > "$MY_DIR/fnalibs.tar.bz2"
    if [ $? -eq 0 ]; then
        echo "Finished downloading!"
    else
        >&2 echo "ERROR: Unable to download successfully."
        exit 1
    fi

    # Decompressing
    echo "Decompressing fnalibs..."
    mkdir -p $MY_DIR/fnalibs
    tar xjC $MY_DIR/fnalibs -f $MY_DIR/fnalibs.tar.bz2
    if [ $? -eq 0 ]; then
        echo "Finished decompressing!"
        rm $MY_DIR/fnalibs.tar.bz2
    else
        >&2 echo "ERROR: Unable to decompress successfully."
        exit 1
    fi
}

# Get the directory of this script
MY_DIR=$(dirname "$BASH_SOURCE")

# FNA
if [ ! -d "$MY_DIR/FNA" ]; then
    read -p "Download FNA (y/n)? " shouldDownload
    if [[ $shouldDownload =~ ^[Yy]$ ]]; then
        downloadFNA
    fi
else
    read -p "Update FNA (y/n)? " shouldUpdate
    if [[ $shouldUpdate =~ ^[Yy]$ ]]; then
        updateFNA
    fi
fi

# FNALIBS
if [ ! -d "$MY_DIR/fnalibs" ]; then
    read -p "Download fnalibs (y/n)? " shouldDownloadLibs
else 
    read -p "Redownload fnalibs (y/n)? " shouldDownloadLibs
fi
if [[ $shouldDownloadLibs =~ ^[Yy]$ ]]; then
    getLibs
fi


# Rename project
read -p "Enter the project name to use for your folder and csproj file or 'exit' to quit: " newProjectName
if [[ $newProjectName = 'exit' ]]; then
    exit 1
fi

sed -i '' "s/project_name/$newProjectName/g" project_name/project_name.csproj
sed -i '' "s/project_name/$newProjectName/g" project_name/Game1.cs
sed -i '' "s/project_name/$newProjectName/g" project_name/Program.cs
sed -i '' "s/project_name/$newProjectName/g" project_name/.vscode/tasks.json
sed -i '' "s/project_name/$newProjectName/g" project_name/.vscode/launch.json

mv project_name/project_name.csproj "project_name/$newProjectName.csproj"
mv project_name "$newProjectName"

git init
git submodule add git@github.com:prime31/Nez.FNA.git
cd Nez.FNA
git submodule init
git submodule update

sleep 10

nuget restore Nez.FNA/Nez/Nez.sln
msbuild Nez.FNA/Nez/Nez.sln