#!/bin/bash

# Log File Analysis Script - Interactive Menu with Advanced Features

# --- Initial Configuration ---
ORIGINAL_LOG_FILE=""
PROCESSED_LOG_FILE="" # This will point to the original or a date-filtered temp file
TOTAL_REQUESTS=0
CURRENT_DATE_FOR_SUGGESTIONS=$(date "+%B %d, %Y")

# --- Default Thresholds (can be overridden by analyzer.conf) ---
FAILURE_RATE_THRESHOLD=5.0
HIGH_IP_ACTIVITY_PERCENTAGE_THRESHOLD=0.05 # 5%
MIN_REQUESTS_FOR_HIGH_IP_ACTIVITY=100
HIGH_POST_COUNT_THRESHOLD=50
MY_DOMAINS="" # Loaded from config

# --- Temporary file for date filtering ---
TEMP_FILTERED_LOG=""

# --- Function to clean up temp file ---
cleanup_temp_file() {
    if [ -n "$TEMP_FILTERED_LOG" ] && [ -f "$TEMP_FILTERED_LOG" ]; then
        rm -f "$TEMP_FILTERED_LOG"
    fi
}
trap cleanup_temp_file EXIT

# --- Load Configuration ---
load_config() {
    local config_file="analyzer.conf"
    if [ -f "$config_file" ]; then
        echo "Loading configuration from $config_file..."
        source "$config_file"
        # Basic validation or logging of loaded values can be added here
    else
        echo "INFO: Configuration file ($config_file) not found. Using default thresholds."
    fi
}

# --- Helper Functions ---
parse_date_to_epoch() {
    # Input: DD/Mon/YYYY:HH:MM:SS
    # Output: epoch seconds, or empty if error
    local log_date_str="$1"
    # Convert Mon to month number for 'date' command
    local day=${log_date_str:0:2}
    local month_name=${log_date_str:3:3}
    local year=${log_date_str:7:4}
    local time=${log_date_str:12:8}

    # A more robust way to convert month name to number if 'date -d' is picky
    # This mapping is for typical English month abbreviations
    case $month_name in
        Jan) month_num="01" ;; Feb) month_num="02" ;; Mar) month_num="03" ;;
        Apr) month_num="04" ;; May) month_num="05" ;; Jun) month_num="06" ;;
        Jul) month_num="07" ;; Aug) month_num="08" ;; Sep) month_num="09" ;;
        Oct) month_num="10" ;; Nov) month_num="11" ;; Dec) month_num="12" ;;
        *) echo ""; return 1 ;; # Invalid month
    esac

    # Format for 'date -d': YYYY-MM-DD HH:MM:SS
    local formatted_date_str="$year-$month_num-$day $time"
    
    # Check if date command can parse it
    local epoch_val=$(date -d "$formatted_date_str" +%s 2>/dev/null)
    if [ -z "$epoch_val" ]; then
      # Fallback for systems where 'Month Day Year' might work better for 'date -d'
      # This part may need adjustment based on the 'date' command's leniency
      formatted_date_str_alt="$month_name $day $year $time"
      epoch_val=$(date -d "$formatted_date_str_alt" +%s 2>/dev/null)
    fi
    echo "$epoch_val"
}


# Function to check if the log file exists and apply date filters
# Usage: check_logfile <filepath> --start-date YYYY-MM-DD --end-date YYYY-MM-DD
# Dates are optional
process_log_file_and_args() {
    ORIGINAL_LOG_FILE="$1"
    shift # Remove log file path from arguments

    local start_date_epoch=""
    local end_date_epoch=""

    # Parse date arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --start-date) start_date_epoch=$(date -d "$2" +%s 2>/dev/null); shift ;;
            --end-date) end_date_epoch=$(date -d "$2" +%s 2>/dev/null); shift ;; # Add 23:59:59 to include the whole end day
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done
    
    if [ -n "$end_date_epoch" ]; then # Adjust end_date_epoch to be end of day
        end_date_epoch=$(date -d "$(date -d "@$end_date_epoch" "+%Y-%m-%d") 23:59:59" +%s 2>/dev/null)
    fi


    if [ -z "$ORIGINAL_LOG_FILE" ]; then
        echo "Error: No log file specified."
        echo "Usage: $0 <path_to_log_file> [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]"
        exit 1
    fi
    if [ ! -f "$ORIGINAL_LOG_FILE" ] || [ ! -r "$ORIGINAL_LOG_FILE" ]; then
        echo "Error: Log file '$ORIGINAL_LOG_FILE' does not exist or is not readable."
        exit 1
    fi

    PROCESSED_LOG_FILE="$ORIGINAL_LOG_FILE" # Default to original

    if [ -n "$start_date_epoch" ] || [ -n "$end_date_epoch" ]; then
        echo "Applying date filters..."
        TEMP_FILTERED_LOG=$(mktemp) # Create a temporary file
        PROCESSED_LOG_FILE="$TEMP_FILTERED_LOG"
        
        local line_count=0
        local filtered_count=0

        while IFS= read -r line; do
            ((line_count++))
            # Extract date part from log line: e.g., [17/May/2015:10:05:03
            local log_entry_date_str=$(echo "$line" | awk '{print substr($4, 2, 20)}') # DD/Mon/YYYY:HH:MM:SS
            local current_line_epoch=$(parse_date_to_epoch "$log_entry_date_str")

            if [ -z "$current_line_epoch" ]; then # Skip if date parsing failed for the line
                # echo "Warning: Could not parse date from line: $line_count" >&2 # Optional warning
                continue
            fi
            
            local include_line=true
            if [ -n "$start_date_epoch" ] && (( current_line_epoch < start_date_epoch )); then
                include_line=false
            fi
            if [ -n "$end_date_epoch" ] && (( current_line_epoch > end_date_epoch )); then
                include_line=false
            fi

            if $include_line; then
                echo "$line" >> "$PROCESSED_LOG_FILE"
                ((filtered_count++))
            fi
        done < "$ORIGINAL_LOG_FILE"
        echo "Date filtering complete. $filtered_count lines selected from $line_count total lines."
        if (( filtered_count == 0 )); then
            echo "Warning: No log entries match the specified date range. Analysis might yield empty results."
        fi
    fi
    
    TOTAL_REQUESTS=$(wc -l < "$PROCESSED_LOG_FILE")
    if (( TOTAL_REQUESTS == 0 && filtered_count > 0 )); then # Should not happen if wc works
        TOTAL_REQUESTS=$filtered_count
    fi
}


# --- Analysis Functions (will now use $PROCESSED_LOG_FILE) ---

# 1. Request Counts
get_request_counts() {
    echo -e "\n--- 1. Request Counts ---"
    echo "Total number of requests (in selected range): $TOTAL_REQUESTS"
    local GET_REQUESTS=$(awk '($6 == "\"GET")' "$PROCESSED_LOG_FILE" | wc -l)
    echo "GET requests: $GET_REQUESTS"
    local POST_REQUESTS=$(awk '($6 == "\"POST")' "$PROCESSED_LOG_FILE" | wc -l)
    echo "POST requests: $POST_REQUESTS"
}

# 2. Unique IP Addresses
get_unique_ips() {
    echo -e "\n--- 2. Unique IP Addresses ---"
    local UNIQUE_IPS_COUNT=$(awk '{print $1}' "$PROCESSED_LOG_FILE" | sort -u | wc -l)
    echo "Total unique IP addresses: $UNIQUE_IPS_COUNT"
    echo -e "\nRequests per unique IP (GET/POST):"
    declare -A ip_get_counts ip_post_counts ip_total_counts
    while read -r ip method; do
        ((ip_total_counts[$ip]++))
        if [[ "$method" == "GET" ]]; then ((ip_get_counts[$ip]++)); fi
        if [[ "$method" == "POST" ]]; then ((ip_post_counts[$ip]++)); fi
    done < <(awk '{gsub(/"/,"",$6); print $1, $6}' "$PROCESSED_LOG_FILE" | grep -E '\b(GET|POST)\b')
    
    local data_to_sort=()
    for ip_addr in "${!ip_total_counts[@]}"; do
        local get_val=${ip_get_counts[$ip_addr]:-0}
        local post_val=${ip_post_counts[$ip_addr]:-0}
        data_to_sort+=("${ip_total_counts[$ip_addr]} $ip_addr $get_val $post_val")
    done
    
    local sorted_data_lines=()
    if [ ${#data_to_sort[@]} -gt 0 ]; then
        mapfile -t sorted_data_lines < <(printf "%s\n" "${data_to_sort[@]}" | sort -k1,1nr -k2,2)
    fi
    local num_lines=${#sorted_data_lines[@]}

    # Ask user for output filename (text or CSV)
    local output_filename=""
    local save_format="text"
    read -rp "Enter filename to save the full IP report (or add .csv extension for CSV format, leave blank to skip): " output_filename
    if [[ "$output_filename" == *.csv ]]; then
        save_format="csv"
    fi

    if [ -n "$output_filename" ]; then
        {
            if [ "$save_format" == "csv" ]; then
                echo "IP_Address,Total_Requests,GET_Requests,POST_Requests"
            else
                echo "IP Address         | Total Reqs | GET Reqs   | POST Reqs  "
                echo "-------------------|------------|------------|------------"
            fi

            if ((num_lines == 0)); then
                if [ "$save_format" != "csv" ]; then echo "No IP data to display for GET/POST requests."; fi
            else
                for line_data in "${sorted_data_lines[@]}"; do
                    read -r current_total_val current_ip_val current_get_val current_post_val <<< "$line_data"
                    if [ "$save_format" == "csv" ]; then
                        printf "%s,%s,%s,%s\n" "$current_ip_val" "$current_total_val" "$current_get_val" "$current_post_val"
                    else
                        printf "%-18s | %-10s | %-10s | %-10s\n" "$current_ip_val" "$current_total_val" "$current_get_val" "$current_post_val"
                    fi
                done
            fi
        } > "$output_filename"
        if [ $? -eq 0 ]; then echo "Full IP report saved to $output_filename (Format: $save_format)"; else echo "Error: Could not save report to $output_filename."; fi
        echo "" 
    fi
    
    # Terminal display (paginated)
    local lines_to_show_initially=30; local count_displayed=0
    echo -e "Displaying paginated IP report on terminal:"
    echo "IP Address         | Total Reqs | GET Reqs   | POST Reqs  "
    echo "-------------------|------------|------------|------------"
    if ((num_lines == 0)); then echo "No IP data to display for GET/POST requests on terminal."; else
        for line_data in "${sorted_data_lines[@]}"; do
            read -r current_total_val current_ip_val current_get_val current_post_val <<< "$line_data"
            printf "%-18s | %-10s | %-10s | %-10s\n" "$current_ip_val" "$current_total_val" "$current_get_val" "$current_post_val"
            ((count_displayed++))
            if (( count_displayed == lines_to_show_initially && num_lines > lines_to_show_initially && count_displayed < num_lines )); then
                read -rp "Showing first $lines_to_show_initially of $num_lines IPs. Press Enter to reveal the rest..."
            fi
        done
    fi
}

# (Other analysis functions 3-10 would similarly use $PROCESSED_LOG_FILE)
# For brevity, I'll only show modification for one more, and then the new functions.
# You'd need to replace "$LOG_FILE" with "$PROCESSED_LOG_FILE" in all awk/grep calls within them.

# 3. Failure Requests
get_failure_requests_data() {
    local failed_count=$(awk '($9 >= 400 && $9 <= 599)' "$PROCESSED_LOG_FILE" | wc -l)
    local percent_failed="0.00"
    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        percent_failed=$(echo "scale=2; ($failed_count * 100) / $TOTAL_REQUESTS" | bc)
    fi
    echo "$failed_count $percent_failed" 
}
get_failure_requests() {
    echo -e "\n--- 3. Failure Requests ---"
    read -r FAILED_REQUESTS_COUNT PERCENT_FAILED <<< "$(get_failure_requests_data)"
    echo "Total failed requests (4xx or 5xx): $FAILED_REQUESTS_COUNT"
    echo "Percentage of failed requests: $PERCENT_FAILED%"
}

# ... (Assume functions 4-10 are updated to use $PROCESSED_LOG_FILE) ...
# Example for one more function update:
# 4. Top User (Most Active IP)
get_top_user_data() {
    awk '{print $1}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2 " " $1}'
}
get_top_user() {
    echo -e "\n--- 4. Top User (Most Active IP) ---"
    read -r TOP_IP TOP_IP_COUNT <<< "$(get_top_user_data)"
    if [ -n "$TOP_IP" ]; then
        echo "Most active IP address: $TOP_IP (with $TOP_IP_COUNT requests)"
    else
        echo "Most active IP address: None found"
    fi
}

# 5. Daily Request Averages
get_daily_request_averages() {
    echo -e "\n--- 5. Daily Request Averages ---"
    local UNIQUE_DAYS=$(awk '{print substr($4, 2, 11)}' "$PROCESSED_LOG_FILE" | sort -u | wc -l)
    if [ "$UNIQUE_DAYS" -gt 0 ]; then
        local AVG_REQUESTS_PER_DAY=$(echo "scale=2; $TOTAL_REQUESTS / $UNIQUE_DAYS" | bc)
        echo "Total unique days found: $UNIQUE_DAYS"
        echo "Average requests per day: $AVG_REQUESTS_PER_DAY"
    else
        echo "Total unique days found: 0"; echo "Average requests per day: 0 (No traffic or unable to parse dates)";
    fi
}

# 6. Days with Highest Failures
get_days_highest_failures_data() {
     awk '($9 >= 400 && $9 <= 599) {print substr($4, 2, 11)}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 5
}
get_days_highest_failures() {
    echo -e "\n--- 6. Days with Highest Failures ---"
    echo "Top 5 days with the most failure requests (4xx/5xx):"
    local output=$(get_days_highest_failures_data)
    if [ -n "$output" ]; then
        echo "$output" | awk '{printf "%-5s failures on %s\n", $1, $2}'
    else
        echo "No failure data to display."
    fi
}

# 7. Request by Hour
get_requests_by_hour_data() {
    awk '{print substr($4, 14, 2)}' "$PROCESSED_LOG_FILE" | sort -n | uniq -c | sort -nr
}
get_requests_by_hour() {
    echo -e "\n--- 7. Requests by Hour of the Day ---"
    echo "Hour | Requests"
    echo "-----|----------"
    get_requests_by_hour_data | awk '{printf "%-4s | %s\n", $2, $1}'
}

# 8. Status Codes Breakdown
get_status_codes_breakdown_data() {
    awk '{print $9}' "$PROCESSED_LOG_FILE" | sort -n | uniq -c | sort -nr
}
get_status_codes_breakdown() {
    echo -e "\n--- 8. Status Codes Breakdown ---"
    echo "Count | Status Code"
    echo "------|-------------"
    get_status_codes_breakdown_data | awk '{printf "%-5s | %s\n", $1, $2}'
}

# 9. Most Active User by Method
get_most_active_user_by_method_data() {
    local top_get_ip_info=$(awk '($6 == "\"GET") {print $1}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2 " " $1}')
    local top_post_ip_info=$(awk '($6 == "\"POST") {print $1}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2 " " $1}')
    echo "$top_get_ip_info"; echo "$top_post_ip_info"
}
get_most_active_user_by_method() {
    echo -e "\n--- 9. Most Active User by Method ---"
    local data_output; data_output=$(get_most_active_user_by_method_data)
    read -r TOP_GET_IP TOP_GET_COUNT <<< "$(echo "$data_output" | sed -n '1p')"
    read -r TOP_POST_IP TOP_POST_COUNT <<< "$(echo "$data_output" | sed -n '2p')"
    if [ -n "$TOP_GET_IP" ]; then echo "IP with most GET requests: $TOP_GET_IP (with $TOP_GET_COUNT GET requests)"; else echo "IP with most GET requests: None found"; fi
    if [ -n "$TOP_POST_IP" ]; then echo "IP with most POST requests: $TOP_POST_IP (with $TOP_POST_COUNT POST requests)"; else echo "IP with most POST requests: None found"; fi
}

# 10. Patterns in Failure Requests (Time)
get_failure_patterns_time_hourly_data() {
    awk '($9 >= 400 && $9 <= 599) {print substr($4, 14, 2)}' "$PROCESSED_LOG_FILE" | sort -n | uniq -c | sort -nr
}
get_failure_patterns_time_daily_data() {
    awk '($9 >= 400 && $9 <= 599) {
        log_date_field = substr($4, 2, 11); split(log_date_field, date_parts, "/");
        day = date_parts[1]; month_str = date_parts[2]; year = date_parts[3];
        reformatted_date = month_str " " day " " year;
        cmd = "date -d \"" reformatted_date "\" +%A 2>/dev/null"; day_of_week = "";
        if ((cmd | getline day_of_week_output) > 0) { day_of_week = day_of_week_output; }
        close(cmd); if (day_of_week != "") { print day_of_week; }
    }' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr
}
get_failure_patterns_time() {
    echo -e "\n--- 10. Patterns in Failure Requests (Time) ---"
    echo -e "\nFailures per Hour of the Day:"; echo "Hour | Failures"; echo "-----|----------"
    local hourly_output=$(get_failure_patterns_time_hourly_data)
    if [ -n "$hourly_output" ]; then echo "$hourly_output" | awk '{printf "%-4s | %s\n", $2, $1}'; else echo "No failure data for hourly breakdown."; fi
    echo -e "\nFailures per Day of the Week:"; echo "Day of Week | Failures"; echo "------------|----------"
    local daily_output=$(get_failure_patterns_time_daily_data)
    if [ -n "$daily_output" ]; then echo "$daily_output" | awk '{printf "%-12s | %s\n", $2, $1}'; else echo "No failure data for day-of-week breakdown."; fi
}


# --- NEW Analysis Functions ---

# 11. User-Agent Analysis
analyze_user_agents() {
    echo -e "\n--- 11. User-Agent Analysis ---"
    echo "Top 10 User-Agents:"
    echo "Count | User-Agent String"
    echo "------|------------------"
    # User agent string can be complex, starts from $12 to the end, enclosed in quotes.
    # Awk command to extract full user agent string (handles spaces within it)
    awk -F'"' '{print $6}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 10 | awk '{count=$1; $1=""; agent=substr($0,2); printf "%-5s | %s\n", count, agent}'

    echo -e "\nBasic Bot Detection (Top 5 by count):"
    echo "Count | Bot Signature"
    echo "------|---------------"
    # Common bot names/signatures (case-insensitive search)
    awk -F'"' 'BEGIN{IGNORECASE=1} 
        /bot|spider|crawler|slurp|scan|semrush|ahrefs|majestic|yandex/ {
            ua = $6; 
            # Try to extract a cleaner bot name if possible, otherwise use full UA
            if (match(ua, /(Googlebot|Bingbot|Slurp|DuckDuckBot|Baiduspider|YandexBot|Sogou|Exabot|facebookexternalhit|LinkedInBot|Twitterbot|Pinterestbot|Discordbot|SemrushBot|AhrefsBot|MJ12bot|DotBot|BLEXBot|Seekport|VoilaBot|TrendictionBot|Dataprovider.com|Applebot|ും)/)) {
                bot_name = substr(ua, RSTART, RLENGTH)
                bots[bot_name]++
            } else {
                 # Fallback for less common or generic names like 'crawler' or 'spider'
                 if (match(ua, /([a-zA-Z0-9_-]+[Bb]ot)/) || match(ua, /([a-zA-Z0-9_-]+[Cc]rawler)/) || match(ua, /([a-zA-Z0-9_-]+[Ss]pider)/) ) {
                    bot_name = substr(ua, RSTART, RLENGTH)
                     bots[bot_name]++
                 } else {
                    # As a last resort, if keyword matched but no specific pattern, count the keyword
                    if (ua ~ /bot/) bots["Generic Bot (contains 'bot')"]++
                    else if (ua ~ /spider/) bots["Generic Spider (contains 'spider')"]++
                    else if (ua ~ /crawler/) bots["Generic Crawler (contains 'crawler')"]++
                 }
            }
        } 
        END {for (b in bots) print bots[b], b}' "$PROCESSED_LOG_FILE" | sort -nr | head -n 5 | awk '{printf "%-5s | %s\n", $1, $2}'
}

# 12. Referer Analysis
analyze_referers() {
    echo -e "\n--- 12. Referer Analysis ---"
    echo "Top 10 Referrers:"
    echo "Count | Referer URL"
    echo "------|------------"
    # Referer is typically the 5th quoted string, so $4 in awk -F'"'
    awk -F'"' '{print $4}' "$PROCESSED_LOG_FILE" | grep -v '^-$\|^$' | sort | uniq -c | sort -nr | head -n 10 | awk '{count=$1; $1=""; referer=substr($0,2); printf "%-5s | %s\n", count, referer}'
    
    local no_referer_count=$(awk -F'"' '($4 == "-")' "$PROCESSED_LOG_FILE" | wc -l)
    echo -e "\nRequests with no Referer (Direct traffic or privacy-stripped): $no_referer_count"

    echo -e "\nPotential External Traffic Sources (Top 5 Domains, excluding own):"
    echo "Count | Referring Domain"
    echo "------|-----------------"
    # Extract domain from referer: //domain.com/
    awk -F'"' '($4 != "-" && $4 != "") {print $4}' "$PROCESSED_LOG_FILE" | \
    awk -F/ '{
        if ($3 != "") { # Ensure there is a domain part after //
            # Check against MY_DOMAINS
            is_own_domain = 0
            split(ENVIRON["MY_DOMAINS"], own_domains_array, " ")
            for (i in own_domains_array) {
                if (index($3, own_domains_array[i]) > 0) {
                    is_own_domain = 1
                    break
                }
            }
            if (is_own_domain == 0) {
                print $3 # Print domain
            }
        }
    }' | \
    sort | uniq -c | sort -nr | head -n 5 | awk '{printf "%-5s | %s\n", $1, $2}'
}


# --- Analysis Suggestions Function (Updated to use config values) ---
generate_analysis_suggestions() {
    echo -e "\n--- Automated Analysis Suggestions (as of $CURRENT_DATE_FOR_SUGGESTIONS) ---"
    echo "Note: These are automated suggestions using thresholds from analyzer.conf (if loaded)."

    # --- 1. Reduce Failures ---
    echo -e "\n[Failures]"
    read -r failed_req_count percent_failed <<< "$(get_failure_requests_data)"
    echo "Overall failure rate: $percent_failed% ($failed_req_count out of $TOTAL_REQUESTS requests)."
    
    if (( $(echo "$percent_failed > $FAILURE_RATE_THRESHOLD" | bc -l) )); then
        echo "  SUGGESTION: Failure rate is above configured threshold of $FAILURE_RATE_THRESHOLD%. Investigation is recommended."
        # ... (rest of failure suggestions as before)
    else
        echo "  INFO: Failure rate is relatively low (<= $FAILURE_RATE_THRESHOLD%). Continue monitoring."
    fi

    # --- 2. Days/Times Needing Attention --- (No specific thresholds from config here yet)
    # ... (as before)

    # --- 3. Security Concerns/Anomalies ---
    echo -e "\n[Security & Anomalies]"
    read -r top_ip top_ip_count <<< "$(get_top_user_data)"
    if [ -n "$top_ip" ]; then
        echo "Most active IP: $top_ip ($top_ip_count requests)."
        local ip_activity_abs_threshold=${MIN_REQUESTS_FOR_HIGH_IP_ACTIVITY:-100} # Default if not in config
        local ip_activity_perc_calc=$(echo "$TOTAL_REQUESTS * $HIGH_IP_ACTIVITY_PERCENTAGE_THRESHOLD" | bc | cut -d. -f1)
        
        # Use the larger of the percentage-based calculation or the absolute minimum
        local effective_threshold=$ip_activity_abs_threshold
        if (( ip_activity_perc_calc > ip_activity_abs_threshold )); then
            effective_threshold=$ip_activity_perc_calc
        fi

        if (( top_ip_count > effective_threshold )); then
            echo "  SUGGESTION: Activity from $top_ip ($top_ip_count requests) is high (threshold: >$effective_threshold requests). Verify if legitimate."
        else
             echo "  INFO: Activity from $top_ip seems within moderate range relative to configured thresholds."
        fi
    fi
    local method_data_output; method_data_output=$(get_most_active_user_by_method_data)
    read -r top_get_ip top_get_count <<< "$(echo "$method_data_output" | sed -n '1p')"
    read -r top_post_ip top_post_count <<< "$(echo "$method_data_output" | sed -n '2p')"
    if [ -n "$top_post_ip" ] && [ "$top_post_count" -gt "${HIGH_POST_COUNT_THRESHOLD:-50}" ]; then
        echo "IP with most POSTs: $top_post_ip ($top_post_count POSTs)."
        echo "  SUGGESTION: High POST activity (>$HIGH_POST_COUNT_THRESHOLD) from $top_post_ip. Investigate for spam/brute-force."
    fi
    # ... (rest of security suggestions as before, using $PROCESSED_LOG_FILE)
    local potential_scans=$(awk '($9 ~ /^(400|401|403|404)$/) && ($7 ~ /(\.git|\.env|wp-login|phpmyadmin|SELECT.*FROM|UNION.*SELECT|<script>)/i) {print "  - Potential probe by " $1 " for " $7 " (Status " $9 ")"}' "$PROCESSED_LOG_FILE" | sort -u | head -n 5)
    if [ -n "$potential_scans" ]; then
        echo "  OBSERVATION: Detected some requests that might indicate scanning or probing activities:"
        echo "$potential_scans"
        echo "  SUGGESTION: Ensure your Web Application Firewall (WAF) is active and up-to-date. Review access controls."
    fi


    # --- 4. System/Service Improvement ---
    # ... (as before, using $PROCESSED_LOG_FILE)
    echo -e "\n[System & Service Improvements]"
    local common_404s=$(awk '($9 == 404){print $7}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 3)
    if [ -n "$common_404s" ]; then
        echo "Top 3 URLs resulting in 404 (Not Found) errors:"
        echo "$common_404s" | awk '{print "  - " $1 " times: " $2}'
        echo "  SUGGESTION: Review these 404s. If they are for legitimate old paths, consider adding 301 redirects. If they are due to typos in your site, fix the links."
    fi
    local common_5xx_errors=$(awk '($9 >= 500 && $9 <= 599){print $9 " " $7}' "$PROCESSED_LOG_FILE" | sort | uniq -c | sort -nr | head -n 3)
     if [ -n "$common_5xx_errors" ]; then
        echo "Top 3 URLs/Patterns associated with 5xx (Server) errors:"
        echo "$common_5xx_errors" | awk '{print "  - " $1 " times: Status " $2 " for " $3}'
        echo "  SUGGESTION: Prioritize investigation of these server errors. Check application and server logs for detailed diagnostics."
    fi
    echo "  INFO: Review 'Requests by Hour' to optimize resource allocation or caching strategies for peak user activity."
    echo "  SUGGESTION: Consider implementing or reviewing rate-limiting policies to protect against abuse."
    echo "  SUGGESTION: Ensure log rotation is configured to manage disk space effectively."

    echo -e "\n--- End of Suggestions ---"
}


# Function to run all analyses
run_all_analyses() {
    echo -e "\n--- Running All Analyses (Data Only) ---"
    get_request_counts
    get_unique_ips
    get_failure_requests
    get_top_user
    get_daily_request_averages
    get_days_highest_failures
    get_requests_by_hour
    get_status_codes_breakdown
    get_most_active_user_by_method
    get_failure_patterns_time
    analyze_user_agents # New
    analyze_referers    # New
    echo -e "\n--- All Analyses Complete ---"
    echo "You can now run 'S' for Automated Suggestions based on this data."
}


# --- Menu System ---
display_menu() {
    echo -e "\nLog File Analysis Menu ($PROCESSED_LOG_FILE)"
    echo "----------------------------------------"
    echo "1. Request Counts"
    echo "2. Unique IP Addresses & GET/POST Counts (Paginated, Save option)"
    echo "3. Failure Requests (Count & Percentage)"
    echo "4. Top User (Most Active IP)"
    echo "5. Daily Request Averages"
    echo "6. Days with Highest Failures"
    echo "7. Requests by Hour of the Day"
    echo "8. Status Codes Breakdown"
    echo "9. Most Active User by Method (GET/POST)"
    echo "10. Patterns in Failure Requests (Hour/Day of Week)"
    echo "11. User-Agent Analysis (Top UAs, Basic Bot Count)"
    echo "12. Referer Analysis (Top Referrers, External Sources)"
    echo "----------------------------------------"
    echo "A. Run ALL Analyses (Data Only)"
    echo "S. Generate Automated Analysis Suggestions"
    echo "Q. Quit"
    echo "----------------------------------------"
}

# --- Main Script Logic ---
load_config # Load settings from analyzer.conf

# Process command-line arguments (log file and optional date filters)
# The first argument MUST be the log file.
# Optional date filters: --start-date YYYY-MM-DD --end-date YYYY-MM-DD
process_log_file_and_args "$@"


while true; do
    display_menu
    read -rp "Enter your choice [1-12, A, S, Q]: " choice

    case "$choice" in
        1) get_request_counts ;;
        2) get_unique_ips ;;
        3) get_failure_requests ;;
        4) get_top_user ;;
        5) get_daily_request_averages ;;
        6) get_days_highest_failures ;;
        7) get_requests_by_hour ;;
        8) get_status_codes_breakdown ;;
        9) get_most_active_user_by_method ;;
        10) get_failure_patterns_time ;;
        11) analyze_user_agents ;; # New
        12) analyze_referers ;;    # New
        A|a) run_all_analyses ;;
        S|s) generate_analysis_suggestions ;;
        Q|q) echo "Exiting."; cleanup_temp_file; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    if [[ ! "$choice" =~ ^[QqAa]$ ]]; then 
      echo ""
      read -rp "Press Enter to continue..."
    fi
done
