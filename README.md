# _BioSample_

# TODO
- Update script names
- Update finalised scripts
- Update input/output file names
- Check correct user inputs in each script
- ADD EXTRACTION OF ISOLATE NAME TO 1_GET_ACCESSIONS FROM XML (CHECK FOR IDS TO BE REMOVED)
- CHECK IF SRATOOLKIT IS ALREADY INSTALLED ON CLUSTER FFS

# Overview

This file describes the scripts used for acquisition, processing and analysis of BioSample WGS SRA files. Broadly, the pipeline as follows:
  - Install NCBI edirect package
  - Install NCBI SRA Toolkit package
  - Identify relevant BioSample IDs
  - Download XML metadata 
  - Source SAMN IDs
  - Convert SAMN IDs to SRR file IDs 
  - Download associated data and convert to FASTQ

These are achieved using 3 scripts, described below in order.

BioProject data used for this project can be found [here](https://www.ncbi.nlm.nih.gov/biosample?LinkName=bioproject_biosample_all&from_uid=925215)

<br>
<br>

# `0_install_packages.sh`

## Description
This script:
  - Downloads and installs edirect and SRA toolkit
  - Adds packages to PATH
  - Updates PATH, and allows packages to be used in the current session

**NOTE:** `sratoolkit_2.10.9-centos_linux64` is downloaded specifically as it works with the `glibc 2.26` that is present on the HPC cluster.

## Input
  - No user input required, script can be run as is

## Output
  - `edirect/` folder created automatically in home directory
  - `sratoolkit_2.10.9-centos_linux64/` folder created automatically in current directory

## Script

```bash
#!/bin/bash

echo
echo "RUNNING 0_install_packages.sh..."
echo
echo "Extracting current directory"

# Get current working directory
PWD="$(pwd)"

echo "Installing NCBI edirect"

# Install edirect
sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"

echo ">> edirect installed"
echo "Downloading SRA toolkit (latest Linux 64-bit)"

# Download SRA toolkit
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz

echo ">> toolkit downloaded"
echo "Extracting toolkit"

# Extract SRA toolkit
tar -xzf sratoolkit.current-ubuntu64.tar.gz

# Get directory name
SRA_DIR=$(tar -tf sratoolkit.current-ubuntu64.tar.gz | head -1 | cut -f1 -d"/")

echo ">> toolkit extracted"
echo "Adding packages to PATH"

# Add edirect to PATH
echo "export PATH=${PWD}/edirect:\${PATH}" >> ${HOME}/.bashrc
# Add SRA toolkit to PATH
echo "export PATH=${PWD}/${SRA_DIR}/bin:\$PATH" >> ${HOME}/.bashrc

echo "Updating PATH"

# Reload for use in current session
source ~/.bashrc

echo
echo "0_install_packages.sh COMPLETE"
echo
```

## Configuration

- Before use, the SRA Toolkit requires some configuration, otherwise the `prefetch` and `fasterq-dump` commands in `2_download_sar.sh` cannot be used
- After running `0_install_packages.sh`, enter the following in the terminal:
```bash
vdb-config --interactive
```
- This launches a text interface for configuration
1. On the `Cache` tab, select `choose` under `location of user-repository`
    - Select `Goto` at the bottom of the window and enter the path to the desired cache folder location e.g. `username/sar_cache`
    - Confirm the location
2. Use the `save` button at the top of the screen to save the configuration
3. Use the `exit` button at the top of the screen to exit configuration

<br>
<br>

# `1_get_accessions.sh`

## Description
This script:
  - Takes a BioProject ID
  - Accesses all BioSample UIDs associated with the BioProject
  - Downloads UIDs, and converts to SAMN accession IDs

## Input

  - User **must specify** desired BioProject ID in line 4 of the script:
  
  ```bash
  BIOPROJECT="PRJNAXXXXXX"
  ```

## Output
  - `biosample_uids.txt` file containing all BioSample UIDs
  - `biosample_docsum.xml` file containing data associated with UIDs
  - `biosample_accessions.txt` file containing all associated SAMN accession IDs for later download

## Script

```bash
#!/bin/bash

# Define BioProject 
BIOPROJECT=""

# Stop if BIOPROJECT is empty
if [[ -z "$BIOPROJECT" ]]; then
    echo "ERROR: BioProject ID not provided. Please edit the script and set a valid BioProject ID."
    exit 1
fi

echo "RUNNING 1_get_accessions.sh..."
echo
echo "Extracting UIDs for BioProject ID ${BIOPROJECT}"

# Extract UIDs
esearch -db bioproject -query "${BIOPROJECT}" \
  | elink -target biosample \
  | efetch -format uid \
  > biosample_uids.txt
  
echo "Extracting XML data"

# Get UID metadata
efetch -db biosample -format docsum < biosample_uids.txt > biosample_docsum.xml

echo "Extracting SAMN accession IDs"

# Get accessions
cat biosample_docsum.xml \
  | xtract -pattern DocumentSummary -element Accession \
  > biosample_accessions.txt

echo "1_get_accessions.sh COMPLETE"
echo
```

<br>
<br>

# `2_download_sar.sh`

## Description
This script:
  - Takes a text file of BioSample SAMN Accession IDs
  - Downloads associated SAR files
  - Converts SAR to FASTQ files

## Input

  - User can specify accession ID text file in line 7 of the script, for testing purposes. By default the `biosample_accessions.txt` output file from `1_get_accessions.sh` is used.
  - User can specify number of threads used for FASTQ conversion, on line 8 of the script. By default 8 threads are used.

## Output

  - 

## Script

