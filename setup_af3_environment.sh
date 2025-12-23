#!/usr/bin/env bash
set -euo pipefail

# Configuration variables - customize these as needed
REPO_URL="https://github.com/AnthonyShiverMicrobes/batch-infer-sherlock.git"
REPO_DIR="$HOME/batch-infer-sherlock"
AF3_DOCKER_IMAGE="docker://YOUR_DOCKER_REGISTRY/alphafold3:latest"  # CUSTOMIZE THIS
SINGULARITY_IMAGE_NAME="alphafold3.sif"
CONDA_ENV_NAME="af3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "AlphaFold3 Environment Setup Script"
echo "================================================"
echo ""

# ============================================================
# 1. Check and setup batch-infer-sherlock repository
# ============================================================
echo "Step 1: Checking for batch-infer-sherlock repository..."
if [ ! -d "$REPO_DIR" ]; then
    echo -e "${GREEN}Repository not found. Cloning from GitHub...${NC}"
    git clone "$REPO_URL" "$REPO_DIR"
    echo -e "${GREEN}Repository cloned successfully!${NC}"
else
    echo -e "${YELLOW}Repository already exists at $REPO_DIR${NC}"
    read -p "Pull and merge latest changes? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Pulling latest changes..."
        cd "$REPO_DIR"
        git pull
        echo -e "${GREEN}Repository updated successfully!${NC}"
        cd - > /dev/null
    else
        echo "Skipping repository update."
    fi
fi
echo ""

# ============================================================
# 2. Create directory structure in $SCRATCH
# ============================================================
echo "Step 2: Creating directory structure in \$SCRATCH..."
if [ -z "${SCRATCH:-}" ]; then
    echo -e "${RED}ERROR: \$SCRATCH environment variable is not set!${NC}"
    echo "Please set \$SCRATCH to your scratch directory path and re-run this script."
    exit 1
fi

# Create main af3 directory
mkdir -p "$SCRATCH/af3"
echo "Created: $SCRATCH/af3"

# Create subdirectories
for subdir in orf msa pool db pred model; do
    mkdir -p "$SCRATCH/af3/$subdir"
    echo "Created: $SCRATCH/af3/$subdir"
done

# Download docker image using singularity
echo ""
echo "Downloading AlphaFold3 docker image using singularity..."
SINGULARITY_IMAGE_PATH="$SCRATCH/af3/$SINGULARITY_IMAGE_NAME"

if [ -f "$SINGULARITY_IMAGE_PATH" ]; then
    echo -e "${YELLOW}Singularity image already exists at $SINGULARITY_IMAGE_PATH${NC}"
    read -p "Re-download the image? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing image and downloading new one..."
        rm "$SINGULARITY_IMAGE_PATH"
        singularity pull "$SINGULARITY_IMAGE_PATH" "$AF3_DOCKER_IMAGE"
        echo -e "${GREEN}Image downloaded successfully!${NC}"
    else
        echo "Keeping existing image."
    fi
else
    echo "Pulling docker image: $AF3_DOCKER_IMAGE"
    singularity pull "$SINGULARITY_IMAGE_PATH" "$AF3_DOCKER_IMAGE"
    echo -e "${GREEN}Image downloaded successfully to $SINGULARITY_IMAGE_PATH${NC}"
fi
echo ""

# ============================================================
# 3. Create conda environment from af3.yaml
# ============================================================
echo "Step 3: Setting up conda environment..."

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo -e "${RED}ERROR: conda command not found!${NC}"
    echo "Please ensure conda is installed and in your PATH."
    exit 1
fi

# Check if environment already exists
if conda env list | grep -q "^$CONDA_ENV_NAME "; then
    echo -e "${YELLOW}Conda environment '$CONDA_ENV_NAME' already exists.${NC}"
    read -p "Recreate the environment? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing environment..."
        conda env remove -n "$CONDA_ENV_NAME" -y
        echo "Creating new environment from $REPO_DIR/af3.yaml..."
        conda env create -f "$REPO_DIR/af3.yaml"
        echo -e "${GREEN}Conda environment created successfully!${NC}"
    else
        echo "Keeping existing environment."
    fi
else
    echo "Creating conda environment from $REPO_DIR/af3.yaml..."
    conda env create -f "$REPO_DIR/af3.yaml"
    echo -e "${GREEN}Conda environment '$CONDA_ENV_NAME' created successfully!${NC}"
fi
echo ""

# ============================================================
# Summary
# ============================================================
echo "================================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Summary:"
echo "  - Repository: $REPO_DIR"
echo "  - Scratch directory: $SCRATCH/af3"
echo "  - Singularity image: $SINGULARITY_IMAGE_PATH"
echo "  - Conda environment: $CONDA_ENV_NAME"
echo ""
echo "To activate the conda environment, run:"
echo "  conda activate $CONDA_ENV_NAME"
echo ""
