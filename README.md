<p align="center">
    <img src="https://capsule-render.vercel.app/api?type=waving&height=200&color=gradient&text=Apache%20Log%20Analyzer%20Script&fontAlignY=40&fontSize=40&fontColor=ffffff" alt="Title Banner"/>
</p>  

<p align="center">
<img src="https://img.shields.io/badge/Made%20With-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white"/>
</p>


# Advanced Interactive Apache Log Analyzer 

## **1. Overview**

This project provides `interactive_log_analyzer.sh`, an advanced Bash script for detailed analysis of Apache web server access logs. It features an interactive command-line menu, enabling users to select from a wide array of analysis modules. The script processes log files to generate statistics on request counts, IP address activity, failure rates, traffic trends, User-Agent distributions, referer sources, and more.

Key enhancements include:
* **Date Range Filtering:** Analyze specific time periods using command-line arguments.
* **Configurable Thresholds:** Customize analytical thresholds for suggestions via an `analyzer.conf` file.
* **User-Agent Analysis:** Identifies top User-Agents and performs basic bot detection.
* **Referer Analysis:** Tracks top referrers and helps identify external traffic sources.
* **Flexible Output:** Option to save detailed reports (like unique IP analysis) in text or CSV format.
* **Automated Insights:** Generates actionable suggestions based on the analyzed data to help identify potential issues, security anomalies, and areas for system optimization.

This tool is designed for system administrators, web developers, and security analysts who need to perform comprehensive log analysis directly from the command line.

## **2. Features**

The script offers the following analysis modules through its interactive menu:

1.  **Request Counts:** Total, GET, and POST request counts.
2.  **Unique IP Addresses:** Total unique IPs; detailed GET/POST counts per IP (paginated, with save-to-file option in text or CSV).
3.  **Failure Requests:** Count and percentage of failed requests (4xx/5xx status codes).
4.  **Top User:** Identifies the most active IP address.
5.  **Daily Request Averages:** Calculates the average number of requests per day within the selected date range.
6.  **Days with Highest Failures:** Lists top days with the most failure requests.
7.  **Requests by Hour:** Shows request distribution throughout the hours of the day.
8.  **Status Codes Breakdown:** Frequency count for each HTTP status code.
9.  **Most Active User by Method:** Identifies IPs with the most GET and POST requests separately.
10. **Patterns in Failure Requests (Time):** Analyzes failures per hour and per day of the week.
11. **User-Agent Analysis:** Top User-Agents and basic bot count.
12. **Referer Analysis:** Top referrers and external traffic sources.
* **Run ALL Analyses (Data Only):** Executes all data-gathering options (1-12).
* **Generate Automated Analysis Suggestions:** Provides insights and recommendations.

## **3. Log File Format**

The script parses log files adhering to the Apache Common Log Format (CLF) or Combined Log Format:
`IP_ADDRESS LOGNAME USER [DD/Mon/YYYY:HH:MM:SS +ZZZZ] "METHOD REQUEST_URI PROTOCOL" STATUS_CODE BYTES_SENT "REFERER" "USER_AGENT"`

## **4. Prerequisites**
* A Bash shell (version 4+ recommended for `mapfile` and associative array features).
* Standard GNU/Linux command-line tools: `awk`, `grep`, `sort`, `uniq`, `wc`, `date` (GNU version recommended), `bc`, `sed`, `head`, `cat`, `mktemp`.

## **5. Setup & Usage**

1.  **Save the Script:** Ensure the script content is saved as `interactive_log_analyzer.sh`.
2.  **Create Configuration File (Optional):** Create an `analyzer.conf` file in the same directory to customize thresholds for suggestions (see "Script Functional Documentation" for details).
3.  **Line Endings:** If copied from Windows, convert line endings:
    ```bash
    dos2unix log_analyzer.sh
    # Or: sed -i 's/\r$//' interactive_log_analyzer.sh
    ```
4.  **Make Executable:**
    ```bash
    chmod +x log_analyzer.sh
    ```
5.  **Run:**
    Execute the script, providing the log file path. Date filtering is optional:
    ```bash
    # Basic execution
    ./log_analyzer.sh /path/to/your/apache_logs.txt

    # With date filtering
    ./log_analyzer.sh /path/to/your/apache_logs.txt --start-date 2015-05-18 --end-date 2015-05-19
    ```
    An interactive menu will appear.

## **6. Available Analyses: Descriptions & Sample Outputs from `apache_logs.txt`**

This section details each analysis module with sample output generated from the `apache_logs.txt` file (10,000 entries, period covering 17/May/2015 to 20/May/2015, as reflected in your provided outputs).

---

### **6.1. Module 1: Request Counts**
* **Description:** Displays total requests, GET requests, and POST requests for the processed log data (respecting any date filters).
* **Sample Output for Module 1:**
    ```text
    --- 1. Request Counts ---
    Total number of requests: 10000
    GET requests: 9952
    POST requests: 5
    ```

---

### **6.2. Module 2: Unique IP Addresses & Their GET/POST Counts**
* **Description:** Calculates total unique IPs. Lists each unique IP with its total, GET, and POST request counts, sorted by total requests. Output to the terminal is paginated. Prompts to save the full report to a file (text or CSV if filename ends with `.csv`).
* **Sample Output for Module 2 (Interaction & File Save Confirmation):**
    ```text
    --- 2. Unique IP Addresses ---
    Total unique IP addresses: 1753

    Requests per unique IP (GET/POST):
    Enter filename to save the full IP report (e.g., ip_report.txt, leave blank to skip saving): ips
    Full IP report saved to ips

    Displaying paginated IP report on terminal:
    IP Address         | Total Reqs | GET Reqs   | POST Reqs  
    -------------------|------------|------------|------------
    [... This is where the script would display the first 30 sorted IPs and their counts. ...]
    [... If more than 30 IPs, a prompt like "Showing first 30 of 1753 IPs. Press Enter to reveal the rest..." would appear. ...]
    ```
    *(The file named `ips` (in this example run) would contain the complete, non-paginated, sorted list of all unique IPs with their respective GET/POST counts.)*

---

### **6.3. Module 3: Failure Requests (Count & Percentage)**
* **Description:** Counts requests with 4xx or 5xx status codes and calculates their percentage relative to total requests.
* **Sample Output for Module 3:**
    ```text
    --- 3. Failure Requests ---
    Total failed requests (4xx or 5xx): 220
    Percentage of failed requests: 2.20%
    ```

---

### **6.4. Module 4: Top User (Most Active IP)**
* **Description:** Identifies the IP address with the highest number of requests.
* **Sample Output for Module 4:**
    ```text
    --- 4. Top User (Most Active IP) ---
    Most active IP address: 66.249.73.135 (with 482 requests)
    ```

---

### **6.5. Module 5: Daily Request Averages**
* **Description:** Calculates the average number of requests per unique day found in the processed log data.
* **Sample Output for Module 5:**
    ```text
    --- 5. Daily Request Averages ---
    Total unique days found: 4
    Average requests per day: 2500.00
    ```

---

### **6.6. Module 6: Days with Highest Failures**
* **Description:** Lists the top 5 days with the most failure requests (4xx/5xx status codes).
* **Sample Output for Module 6:**
    ```text
    --- 6. Days with Highest Failures ---
    Top 5 days with the most failure requests (4xx/5xx):
    66    failures on 19/May/2015
    66    failures on 18/May/2015
    58    failures on 20/May/2015
    30    failures on 17/May/2015
    ```

---

### **6.7. Module 7: Requests by Hour of the Day**
* **Description:** Shows request distribution by hour (00-23), sorted by hour.
* **Sample Output for Module 7:**
    ```text
    --- 7. Requests by Hour of the Day ---
    Hour | Requests
    -----|----------
    14   | 498
    15   | 496
    19   | 493
    20   | 486
    17   | 484
    18   | 478
    13   | 475
    16   | 473
    12   | 462
    11   | 459
    21   | 453
    10   | 443
    05   | 371
    06   | 366
    02   | 365
    09   | 364
    00   | 361
    01   | 360
    07   | 357
    23   | 356
    04   | 355
    03   | 354
    22   | 346
    08   | 345
    ```

---

### **6.8. Module 8: Status Codes Breakdown**
* **Description:** Provides a frequency count for each HTTP status code, sorted by frequency.
* **Sample Output for Module 8:**
    ```text
    --- 8. Status Codes Breakdown ---
    Count | Status Code
    ------|-------------
    9126  | 200
    445   | 304
    213   | 404
    164   | 301
    45    | 206
    3     | 500
    2     | 416
    2     | 403
    ```

---

### **6.9. Module 9: Most Active User by Method (GET/POST)**
* **Description:** Identifies the IP with the most GET requests and the IP with the most POST requests.
* **Sample Output for Module 9:**
    ```text
    --- 9. Most Active User by Method ---
    IP with most GET requests: 66.249.73.135 (with 482 GET requests)
    IP with most POST requests: 78.173.140.106 (with 3 POST requests)
    ```

---

### **6.10. Module 10: Patterns in Failure Requests (Hour/Day of Week)**
* **Description:** Analyzes failure request patterns by hour and by day of the week.
* **Sample Output for Module 10:**
    ```text
    --- 10. Patterns in Failure Requests (Time) ---

    Failures per Hour of the Day:
    Hour | Failures
    -----|----------
    09   | 18
    05   | 15
    06   | 14
    17   | 12
    13   | 12
    10   | 12
    14   | 11
    11   | 11
    19   | 10
    02   | 10
    01   | 10
    18   | 9
    04   | 9
    22   | 8
    21   | 8
    16   | 8
    12   | 7
    07   | 7
    03   | 7
    15   | 6
    00   | 6
    23   | 4
    20   | 4
    08   | 2

    Failures per Day of the Week:
    Day of Week | Failures
    ------------|----------
    Tuesday      | 66
    Monday       | 66
    Wednesday    | 58
    Sunday       | 30
    ```

---

### **6.11. Module 11: User-Agent Analysis**
* **Description:** Lists the top 10 User-Agent strings and provides a basic count of common bot signatures.
* **Sample Output for Module 11:**
    ```text
    --- 11. User-Agent Analysis ---
    Top 10 User-Agents:
    Count | User-Agent String
    ------|------------------
    1044  | Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36
    369   | Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.91 Safari/537.36
    364   | UniversalFeedParser/4.2-pre-314-svn +[http://feedparser.org/](http://feedparser.org/)
    296   | Mozilla/5.0 (Windows NT 6.1; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0
    271   | Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5376e Safari/8536.25 (compatible; Googlebot/2.1; +[http://www.google.com/bot.html](http://www.google.com/bot.html))
    268   | Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36
    237   | Mozilla/5.0 (compatible; Googlebot/2.1; +[http://www.google.com/bot.html](http://www.google.com/bot.html))
    236   | Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:27.0) Gecko/20100101 Firefox/27.0
    229   | Mozilla/5.0 (X11; Linux x86_64; rv:27.0) Gecko/20100101 Firefox/27.0
    198   | Tiny Tiny RSS/1.11 ([http://tt-rss.org/](http://tt-rss.org/))

    Basic Bot Detection (Top 5 by count):
    Count | Bot Signature
    ------|---------------
    543   | Googlebot
    171   | org_bot
    118   | msnbot
    106   | Slurp
    84    | Baiduspider
    ```

---

### **6.12. Module 12: Referer Analysis**
* **Description:** Lists the top 10 referrers, counts requests with no referrer, and attempts to identify top external referring domains.
* **Sample Output for Module 12:**
    ```text
    --- 12. Referer Analysis ---
    Top 10 Referrers:
    Count | Referer URL
    ------|------------
    689   | [http://semicomplete.com/presentations/logstash-puppetconf-2012/](http://semicomplete.com/presentations/logstash-puppetconf-2012/)
    656   | [http://www.semicomplete.com/projects/xdotool/](http://www.semicomplete.com/projects/xdotool/)
    406   | [http://semicomplete.com/presentations/logstash-scale11x/](http://semicomplete.com/presentations/logstash-scale11x/)
    335   | [http://www.semicomplete.com/articles/dynamic-dns-with-dhcp/](http://www.semicomplete.com/articles/dynamic-dns-with-dhcp/)
    228   | [http://www.semicomplete.com/](http://www.semicomplete.com/)
    200   | [http://www.semicomplete.com/style2.css](http://www.semicomplete.com/style2.css)
    164   | [http://semicomplete.com/](http://semicomplete.com/)
    148   | [http://semicomplete.com/presentations/logstash-monitorama-2013/](http://semicomplete.com/presentations/logstash-monitorama-2013/)
    144   | [http://www.semicomplete.com/blog/geekery/ssl-latency.html](http://www.semicomplete.com/blog/geekery/ssl-latency.html)
    123   | [http://semicomplete.com/presentations/logstash-1/](http://semicomplete.com/presentations/logstash-1/)

    Requests with no Referer (Direct traffic or privacy-stripped): 4073

    Potential External Traffic Sources (Top 5 Domains, excluding own):
    Count | Referring Domain
    ------|-----------------
    3038  | [www.semicomplete.com](https://www.semicomplete.com)
    2001  | semicomplete.com
    228   | [www.google.com](https://www.google.com)
    46    | www.google.fr
    37    | www.google.co.uk
    ```
    *(Note: The "Potential External Traffic Sources" depends on the `MY_DOMAINS` setting in `analyzer.conf`. In this sample, if "semicomplete.com" domains were correctly excluded, only google.com, google.fr, etc., would show as truly external.)*


---

### **6.13. Module S: Automated Analysis Suggestions**
* **Description:** Synthesizes data from various analyses to provide automated insights and actionable suggestions regarding failure reduction, peak activity management, potential security concerns, and system/service improvements.
* **Sample Output for Module S:**
    ```text
    --- Automated Analysis Suggestions (as of May 09, 2025) ---
    Note: These are automated suggestions. Always correlate with specific system knowledge.

    [Failures]
    Overall failure rate: 2.20% (220 out of 10000 requests).
      INFO: Failure rate is relatively low (<= 5.00%). Continue monitoring.

    [Peak Activity & Failure Trends]
    Highest traffic hour: 14:00 (with approx. 498 requests).
      SUGGESTION: Ensure server resources are adequate for peak hours. Schedule maintenance outside these times.
    Day with most failures: 19/May/2015 (approx. 66 failures).
      SUGGESTION: Investigate server/application activity on 19/May/2015 to understand causes.
    Hour with most failures: 09:00 (with approx. 18 failures).
      SUGGESTION: If this correlates with peak traffic, it may indicate load-related issues.

    [Security & Anomalies]
    Most active IP: 66.249.73.135 (482 requests).
      INFO: Activity from 66.249.73.135 seems within a moderate range relative to total traffic, but manual verification is always good practice for top talkers.
      INFO: Regularly check for suspicious User-Agents, or unusual request sequences (e.g., rapid-fire requests).
      OBSERVATION: Detected some requests that might indicate scanning or probing activities:
      - Potential probe by 101.119.18.35 for /presentations/logstash-puppetconf-2012/images/office-space-printer-beat-down-gif.gif (Status 404)
      - Potential probe by 101.226.168.198 for /blog/geekery/jquery-interface-/p%20ppuffer.html (Status 404)
      - Potential probe by 111.199.235.239 for /presentations/logstash-puppetconf-2012/images/office-space-printer-beat-down-gif.gif (Status 404)
      - Potential probe by 115.112.233.75 for /presentations/logstash-puppetconf-2012/images/office-space-printer-beat-down-gif.gif (Status 404)
      - Potential probe by 122.166.142.108 for /presentations/logstash-puppetconf-2012/images/office-space-printer-beat-down-gif.gif (Status 404)
      SUGGESTION: Ensure your Web Application Firewall (WAF) is active and up-to-date. Review access controls.

    [System & Service Improvements]
    Top 3 URLs resulting in 404 (Not Found) errors:
      - 61 times: /files/logstash/logstash-1.3.2-monolithic.jar
      - 32 times: /presentations/logstash-puppetconf-2012/images/office-space-printer-beat-down-gif.gif
      - 6 times: /wp/wp-admin/
      SUGGESTION: Review these 404s. If they are for legitimate old paths, consider adding 301 redirects. If they are due to typos in your site, fix the links.
    Top 3 URLs/Patterns associated with 5xx (Server) errors:
      - 2 times: Status 500 for /misc/Title.php.txt
      - 1 times: Status 500 for /projects/xdotool/
      SUGGESTION: Prioritize investigation of these server errors. Check application and server logs for detailed diagnostics.
      INFO: Review 'Requests by Hour' to optimize resource allocation or caching strategies for peak user activity.
      SUGGESTION: Consider implementing or reviewing rate-limiting policies to protect against abuse.
      SUGGESTION: Ensure log rotation is configured to manage disk space effectively.

    --- End of Suggestions ---
    ```

---

## **7. Script Functional Documentation (`log_analyzer.sh`)**

This section describes the purpose and high-level logic of the main functions within the script, corresponding to the menu options. **It does not include the full Bash code for each function in this descriptive part.**

### **Overall Script Structure**
The script initializes by setting up global variables and loading an optional configuration file (`analyzer.conf`). It processes command-line arguments for the log file path and optional date range filters. A main helper function, `process_log_file_and_args()`, validates the input log and applies date filters by creating a temporary processed log file if necessary. All subsequent analysis functions operate on this `PROCESSED_LOG_FILE`. The core of the script is an interactive menu system that calls specific analysis functions based on user input.

### **Global Variables**
* `ORIGINAL_LOG_FILE`: Path to the original log file provided by the user.
* `PROCESSED_LOG_FILE`: Path to the log data being analyzed (either original or date-filtered temporary file).
* `TOTAL_REQUESTS`: Total requests in `PROCESSED_LOG_FILE`.
* `CURRENT_DATE_FOR_SUGGESTIONS`: Date used in suggestions header.
* Variables for thresholds (e.g., `FAILURE_RATE_THRESHOLD`): Loaded from `analyzer.conf` or use defaults.
* `MY_DOMAINS`: List of user's own domains for referer analysis, loaded from `analyzer.conf`.
* `TEMP_FILTERED_LOG`: Path to the temporary file if date filtering is active.

### **Helper and Core Logic Functions**
* **`cleanup_temp_file()`**: Ensures any temporary filtered log file is removed on script exit (via `trap`).
* **`load_config()`**: Sources `analyzer.conf` if it exists, allowing user-defined thresholds to override defaults.
* **`parse_date_to_epoch(log_date_str)`**: Converts a log timestamp string (e.g., `DD/Mon/YYYY:HH:MM:SS`) into Unix epoch seconds for date comparisons. Handles month name to number conversion.
* **`process_log_file_and_args("$@")`**:
    * Parses command-line arguments for the log file path and optional `--start-date` and `--end-date`.
    * Validates the log file.
    * If date filters are given, it iterates through `ORIGINAL_LOG_FILE`, converts log entry timestamps to epoch, and writes matching lines to `TEMP_FILTERED_LOG`. Sets `PROCESSED_LOG_FILE` to this temporary file.
    * Calculates `TOTAL_REQUESTS` based on `PROCESSED_LOG_FILE`.

### **Analysis Function Descriptions (Modules 1-12 & Suggestions)**

* **Module 1: `get_request_counts()`**
    * Displays `TOTAL_REQUESTS`. Uses `awk` and `wc -l` on `$PROCESSED_LOG_FILE` to count GET (field `$6` matches `"GET"`) and POST (field `$6` matches `"POST"`) requests.

* **Module 2: `get_unique_ips()`**
    * Calculates total unique IPs from `$PROCESSED_LOG_FILE` (field `$1`) using `awk | sort -u | wc -l`.
    * For per-IP details: populates Bash associative arrays for GET/POST counts. Data is prepared (total count, IP, GET count, POST count), sorted numerically by total count (descending) then IP, and read into an array using `mapfile`.
    * Prompts to save the full sorted report to a user-specified file (text or CSV). Displays paginated output to the terminal.

* **Module 3: `get_failure_requests()` (uses `get_failure_requests_data()`)**
    * `_data` function counts lines in `$PROCESSED_LOG_FILE` where status code (field `$9`) is 4xx or 5xx using `awk | wc -l`. Calculates percentage using `bc`.
    * Main function formats and displays these.

* **Module 4: `get_top_user()` (uses `get_top_user_data()`)**
    * `_data` function extracts IPs (field `$1`) from `$PROCESSED_LOG_FILE`, then uses `sort | uniq -c | sort -nr | head -n 1` to find the most frequent.

* **Module 5: `get_daily_request_averages()`**
    * Extracts dates (from field `$4`) in `$PROCESSED_LOG_FILE`, finds unique day count (`sort -u | wc -l`), then divides `TOTAL_REQUESTS` by unique days using `bc`.

* **Module 6: `get_days_highest_failures()` (uses `get_days_highest_failures_data()`)**
    * `_data` function filters `$PROCESSED_LOG_FILE` for 4xx/5xx status codes, extracts dates, then `sort | uniq -c | sort -nr | head -n 5` to find top failing days.

* **Module 7: `get_requests_by_hour()` (uses `get_requests_by_hour_data()`)**
    * `_data` function extracts hour (from field `$4`) from `$PROCESSED_LOG_FILE`, then `sort -n | uniq -c | sort -nr` to get hourly counts (sorted by count for `_data`, by hour for display).

* **Module 8: `get_status_codes_breakdown()` (uses `get_status_codes_breakdown_data()`)**
    * `_data` function extracts status codes (field `$9`) from `$PROCESSED_LOG_FILE`, then `sort -n | uniq -c | sort -nr` for frequency.

* **Module 9: `get_most_active_user_by_method()` (uses `get_most_active_user_by_method_data()`)**
    * `_data` function filters `$PROCESSED_LOG_FILE` for GET requests then finds top IP; repeats for POST requests.

* **Module 10: `get_failure_patterns_time()` (uses `_hourly_data()` and `_daily_data()` variants)**
    * Hourly: Filters `$PROCESSED_LOG_FILE` for 4xx/5xx, extracts hour, then `sort -n | uniq -c | sort -nr`.
    * Daily: Filters for 4xx/5xx, extracts date, uses `getline` with `date -d` to get day of week, then `sort | uniq -c | sort -nr`.

* **Module 11: `analyze_user_agents()`**
    * Extracts full User-Agent string (field `$6` using `awk -F'"'`) from `$PROCESSED_LOG_FILE`. Uses `sort | uniq -c | sort -nr | head -n 10` for top UAs.
    * Performs basic bot detection by `awk`-ing through UAs for common keywords/signatures.

* **Module 12: `analyze_referers()`**
    * Extracts Referer string (field `$4` using `awk -F'"'`) from `$PROCESSED_LOG_FILE`. Uses `sort | uniq -c | sort -nr | head -n 10` for top referrers.
    * Counts direct/empty referers.
    * Attempts to identify external referring domains by parsing domains from referer URLs and comparing against `MY_DOMAINS` from `analyzer.conf`.

* **Module S: `generate_analysis_suggestions()`**
    * Calls various `_data()` functions to fetch metrics.
    * Applies conditional logic and thresholds (from `analyzer.conf` or defaults) to generate textual advice on failures, peak activity, security, and system improvements. Includes basic heuristic for potential web scanning.

### **Menu System**
* **`display_menu()`**: Prints the interactive menu options.
* **Main `while` loop with `case` statement**: Handles user input, calls corresponding functions, and manages the interactive flow with "Press Enter to continue" prompts.

## **9\. Interpreting the Output & Suggestions**

  * **Context is Crucial:** Always interpret the script's output and suggestions in the context of your specific server environment, expected traffic, and recent changes.
  * **Thresholds:** The default thresholds in the suggestions engine (and in `analyzer.conf`) are general starting points. Adjust them based on your baseline and operational requirements.
  * **Drill Down:** Use the script's findings as indicators. For example, if high 5xx errors are reported, the next step is to check detailed application and server error logs for root causes.
  * **Security:** The security-related suggestions are basic heuristics. For comprehensive security monitoring, use dedicated tools like WAFs, IDS/IPS, and SIEMs.

---
