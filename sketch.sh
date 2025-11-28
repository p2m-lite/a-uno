#!/bin/bash

# --- CONFIGURATION ---
FQBN="arduino:avr:uno"
PORT="/dev/ttyACM0"
BAUD="9600"

# --- COLORS ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. CHECK ARGUMENTS
if [ -z "$1" ]; then
    echo -e "${RED}Error: No sketch name provided.${NC}"
    echo "Usage: $0 <SketchName>"
    exit 1
fi

SKETCH_NAME=$1
SKETCH_PATH="./$SKETCH_NAME/$SKETCH_NAME.ino"

# 2. CHECK EXISTENCE & HANDLE EDITING LOGIC
if [ -f "$SKETCH_PATH" ]; then
    # --- SCENARIO A: SKETCH EXISTS ---
    echo -e "${GREEN}Found existing sketch: $SKETCH_NAME${NC}"
    
    # Ask user if they want to edit
    echo -n "Do you want to edit the code using nano? [y/N]: "
    read -r EDIT_CHOICE
    
    if [[ "$EDIT_CHOICE" =~ ^[Yy] ]]; then
        nano "$SKETCH_PATH"
    else
        echo "Skipping edit..."
    fi

else
    # --- SCENARIO B: CREATE NEW & FORCE EDIT ---
    echo -e "${CYAN}Sketch '$SKETCH_NAME' not found. Creating new sketch...${NC}"
    arduino-cli sketch new "$SKETCH_NAME"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully created. Opening nano...${NC}"
        sleep 2s # Short pause
        nano "$SKETCH_PATH"
    else
        echo -e "${RED}Failed to create sketch. Exiting.${NC}"
        exit 1
    fi
fi

# 3. COMPILE
echo -e "${YELLOW}--- Compiling Sketch: $SKETCH_NAME ---${NC}"
arduino-cli compile --fqbn $FQBN "$SKETCH_NAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed. Aborting upload.${NC}"
    exit 1
else
    echo -e "${GREEN}Compilation Successful!${NC}"
fi

# 4. UPLOAD
echo -e "${YELLOW}--- Uploading to $PORT ---${NC}"
arduino-cli upload -p $PORT --fqbn $FQBN "$SKETCH_NAME"

if [ $? -ne 0 ]; then
    echo -e "${RED}Upload failed. Check your connection/port.${NC}"
    exit 1
else
    echo -e "${GREEN}Upload Successful!${NC}"
fi

# 5. MONITOR
echo -e "${YELLOW}--- Starting Serial Monitor (Ctrl+C to exit) ---${NC}"
arduino-cli monitor -p $PORT --config baudrate=$BAUD
