#!/bin/bash

# viral_kan_error_miner.sh - Extracts and categorizes all errors from logs
# Created: $(date)
# Usage: ./viral_kan_error_miner.sh [logfile]

# Colors for output
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# ASCII Art Header
echo -e "${GREEN}
  _   _ _   _ _  __  ___ _   _ ___ 
 | | | | | | | |/ / | _ \ | | / __|
 | |_| | |_| | ' /  |   / |_| \__ \\
  \___/ \___/|_|\_\ |_|_\\___/ |___/
  Error Miner v1.0
${NC}"

# Find latest log file if none specified
if [ -z "$1" ]; then
    LOG_FILE=$(ls -t logs/viral_kan_debug_*.log 2>/dev/null | head -n 1)
    if [ -z "$LOG_FILE" ]; then
        LOG_FILE=$(ls -t *.log 2>/dev/null | head -n 1)
    fi
else
    LOG_FILE="$1"
fi

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}✖ Error: No log file found${NC}"
    echo "Please either:"
    echo "1. Specify a log file: ./viral_kan_error_miner.sh path/to/log.log"
    echo "2. Run the debugger first to generate logs"
    exit 1
fi

echo -e "\n${CYAN}🔍 Analyzing: ${GREEN}$LOG_FILE${NC}"
echo -e "${YELLOW}⏳ Processing...${NC}\n"

# 1. Extract and count unique errors
echo -e "${YELLOW}📛 TOP ERRORS FOUND:${NC}"
grep -E 'ERROR:|Error:|Exception:|Traceback|failed' "$LOG_FILE" | \
    sed -e 's/^.*\(ERROR\|Error\|Exception\):/\1:/i' -e 's/^.*Traceback.*/Traceback/' | \
    sort | uniq -c | sort -nr | head -n 10 | \
    while read -r count error; do
        printf "${RED}%4s x ${CYAN}%-120s${NC}\n" "$count" "${error:0:120}"
    done

# 2. Show Python exceptions with context
echo -e "\n${YELLOW}🐍 PYTHON EXCEPTIONS:${NC}"
grep -n -A 3 'Traceback' "$LOG_FILE" | \
    awk 'BEGIN {RS="--"; FS="\n"} {if ($2 ~ /File "/) print $1,$2,$3}' | \
    sort | uniq -c | sort -nr | head -n 5 | \
    while read -r count line file error; do
        printf "${RED}%4s x ${CYAN}%-20s ${YELLOW}%-40s\n${NC}      ${RED}➔${NC} %s${NC}\n" \
               "$count" "${file##*\"}" "${line%%:*}" "${error:0:100}"
    done

# 3. File system errors
echo -e "\n${YELLOW}📂 FILE SYSTEM ERRORS:${NC}"
grep -E 'No such file|not found|permission denied|cannot access' "$LOG_FILE" | \
    sort | uniq | head -n 5 | \
    while read -r error; do
        echo -e "${RED}➔ ${CYAN}${error:0:120}${NC}"
    done

# 4. Dependency issues
echo -e "\n${YELLOW}🧩 DEPENDENCY ISSUES:${NC}"
grep -E 'Could not find|No matching distribution|not installed|not available' "$LOG_FILE" | \
    sort | uniq | head -n 5 | \
    while read -r error; do
        echo -e "${RED}➔ ${CYAN}${error:0:120}${NC}"
    done

# 5. Show summary stats
TOTAL_ERRORS=$(grep -c -E 'ERROR:|Error:|Exception:|Traceback|failed' "$LOG_FILE")
UNIQUE_ERRORS=$(grep -E 'ERROR:|Error:|Exception:|Traceback|failed' "$LOG_FILE" | sort | uniq | wc -l)
FIRST_ERROR=$(grep -E 'ERROR:|Error:|Exception:|Traceback|failed' "$LOG_FILE" | head -n 1 | cut -c1-100)
LAST_ERROR=$(grep -E 'ERROR:|Error:|Exception:|Traceback|failed' "$LOG_FILE" | tail -n 1 | cut -c1-100)

echo -e "\n${GREEN}📊 ERROR STATISTICS:${NC}"
printf "${CYAN}%-20s ${RED}%s${NC}\n" "Total errors:" "$TOTAL_ERRORS"
printf "${CYAN}%-20s ${RED}%s${NC}\n" "Unique errors:" "$UNIQUE_ERRORS"
printf "${CYAN}%-20s ${YELLOW}%s${NC}\n" "First error:" "$FIRST_ERROR"
printf "${CYAN}%-20s ${YELLOW}%s${NC}\n" "Last error:" "$LAST_ERROR"

# 6. Show most error-prone files
echo -e "\n${YELLOW}🚨 MOST ERROR-PRONE FILES:${NC}"
grep 'File "' "$LOG_FILE" | \
    awk -F'"' '{print $2}' | \
    sort | uniq -c | sort -nr | head -n 3 | \
    while read -r count file; do
        printf "${RED}%4s x ${CYAN}%-60s${NC}\n" "$count" "$file"
    done

echo -e "\n${GREEN}✅ Analysis complete!${NC}"
echo -e "Use ${YELLOW}less -R ${LOG_FILE}${NC} to view full logs"

