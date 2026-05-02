#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  TaskLang++ Automated Test Runner
#  Runs all valid, invalid, and semantic tests and reports results
# ═══════════════════════════════════════════════════════════════

BINARY="./tasklang"
TEST_DIR="./tests"
PASS=0
FAIL=0
TOTAL=0

# ── Colours for terminal output ──────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Check binary exists ───────────────────────────────────────
if [ ! -f "$BINARY" ]; then
    echo -e "${RED}ERROR: '$BINARY' not found. Run 'make' first.${RESET}"
    exit 1
fi

# ═════════════════════════════════════════════════════════════
#  run_valid <file> <description>
#  Expects the parser to EXIT 0 (success) and produce no
#  [Parse Error] lines in stderr.
# ═════════════════════════════════════════════════════════════
run_valid() {
    local file=$1
    local desc=$2
    TOTAL=$((TOTAL + 1))

    output=$($BINARY < "$file" 2>&1)
    exit_code=$?

    # A valid program must not contain any error lines
    if echo "$output" | grep -qiE "\[Parse Error\]|\[Lexical Error\]"; then
        echo -e "  ${RED}[FAIL]${RESET} $desc"
        echo -e "         File   : $file"
        echo -e "         Reason : Unexpected error in valid program"
        echo "$output" | grep -iE "\[Parse Error\]|\[Lexical Error\]" | sed 's/^/         → /'
        FAIL=$((FAIL + 1))
    else
        echo -e "  ${GREEN}[PASS]${RESET} $desc"
        PASS=$((PASS + 1))
    fi
}

# ═════════════════════════════════════════════════════════════
#  run_invalid <file> <description>
#  Expects the parser to produce a [Parse Error] or
#  [Lexical Error] in its output.
# ═════════════════════════════════════════════════════════════
run_invalid() {
    local file=$1
    local desc=$2
    TOTAL=$((TOTAL + 1))

    output=$($BINARY < "$file" 2>&1)

    if echo "$output" | grep -qiE "\[Parse Error\]|\[Lexical Error\]"; then
        echo -e "  ${GREEN}[PASS]${RESET} $desc"
        error_line=$(echo "$output" | grep -iE "\[Parse Error\]|\[Lexical Error\]" | head -1)
        echo -e "         Caught : $error_line"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${RESET} $desc"
        echo -e "         File   : $file"
        echo -e "         Reason : Expected an error but parser accepted the input"
        FAIL=$((FAIL + 1))
    fi
}

# ═════════════════════════════════════════════════════════════
#  run_semantic <file> <description> <expected_keyword>
#  Expects the output to contain a [Semantic Error] with a
#  specific keyword (e.g. "Circular" or "unknown")
# ═════════════════════════════════════════════════════════════
run_semantic() {
    local file=$1
    local desc=$2
    local keyword=$3
    TOTAL=$((TOTAL + 1))

    output=$($BINARY < "$file" 2>&1)

    if echo "$output" | grep -qi "\[Semantic Error\].*$keyword"; then
        echo -e "  ${GREEN}[PASS]${RESET} $desc"
        sem_line=$(echo "$output" | grep -i "\[Semantic Error\]" | head -1)
        echo -e "         Caught : $sem_line"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${RESET} $desc"
        echo -e "         File   : $file"
        echo -e "         Reason : Expected [Semantic Error] containing '$keyword'"
        FAIL=$((FAIL + 1))
    fi
}

# ═════════════════════════════════════════════════════════════
#  VALID TESTS — parser must accept these
# ═════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}  VALID PROGRAM TESTS (must all PASS)   ${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

run_valid  "tests/valid/v01_simple_daily.tsl"         "V01 Simple daily task"
run_valid  "tests/valid/v02_weekly_task.tsl"           "V02 Weekly scheduled task"
run_valid  "tests/valid/v03_at_schedule.tsl"           "V03 AT-only schedule"
run_valid  "tests/valid/v04_after_if_success.tsl"      "V04 AFTER + IF success"
run_valid  "tests/valid/v05_if_failure.tsl"            "V05 IF failure condition"
run_valid  "tests/valid/v06_depends_on.tsl"            "V06 DEPENDS ON syntax"
run_valid  "tests/valid/v07_before_syntax.tsl"         "V07 BEFORE syntax"
run_valid  "tests/valid/v08_no_schedule.tsl"           "V08 Task with no schedule"
run_valid  "tests/valid/v09_minimal_task.tsl"          "V09 Minimal task (RUN only)"
run_valid  "tests/valid/v10_all_weekdays.tsl"          "V10 All seven weekdays"
run_valid  "tests/valid/v11_long_chain.tsl"            "V11 Long chained workflow"
run_valid  "tests/valid/v12_with_comments.tsl"         "V12 Comments in source"
run_valid  "tests/valid/v13_edge_times.tsl"            "V13 Edge times 00:00 and 23:59"
run_valid  "tests/valid/v14_complex_identifiers.tsl"   "V14 Complex identifier names"

# ═════════════════════════════════════════════════════════════
#  INVALID TESTS — parser must reject these with errors
# ═════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}  SYNTAX ERROR TESTS (must all PASS)    ${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

run_invalid "tests/invalid/i01_missing_run.tsl"             "I01 Missing RUN statement"
run_invalid "tests/invalid/i02_missing_task_name.tsl"       "I02 Missing task name"
run_invalid "tests/invalid/i03_missing_open_brace.tsl"      "I03 Missing opening brace"
run_invalid "tests/invalid/i04_missing_close_brace.tsl"     "I04 Missing closing brace"
run_invalid "tests/invalid/i05_missing_task_keyword.tsl"    "I05 Missing TASK keyword"
run_invalid "tests/invalid/i06_missing_run_string.tsl"      "I06 Missing string after RUN"
run_invalid "tests/invalid/i07_missing_time.tsl"            "I07 Missing TIME after AT"
run_invalid "tests/invalid/i08_if_no_condition.tsl"         "I08 IF without condition"
run_invalid "tests/invalid/i09_unknown_keyword.tsl"         "I09 Unknown keyword DAILY"
run_invalid "tests/invalid/i10_after_no_identifier.tsl"     "I10 AFTER without identifier"
run_invalid "tests/invalid/i11_invalid_time_format.tsl"     "I11 Invalid time format 6:00"
run_invalid "tests/invalid/i12_identifier_starts_digit.tsl" "I12 Identifier starts with digit"
run_invalid "tests/invalid/i13_unquoted_string.tsl"         "I13 Unquoted string in RUN"
run_invalid "tests/invalid/i14_empty_program.tsl"           "I14 Empty program"
run_invalid "tests/invalid/i15_typo_keyword.tsl"            "I15 Typo in keyword EVRY"

# ═════════════════════════════════════════════════════════════
#  SEMANTIC TESTS — parser accepts but semantic check fails
# ═════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}${CYAN}  SEMANTIC ERROR TESTS (must all PASS)  ${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

run_semantic "tests/semantic/s01_circular_direct.tsl"      "S01 Direct circular A->B->A"        "Circular"
run_semantic "tests/semantic/s02_circular_three_way.tsl"   "S02 Three-way circular A->B->C->A"  "Circular"
run_semantic "tests/semantic/s03_self_dependency.tsl"      "S03 Self-dependency A->A"           "Circular"
run_semantic "tests/semantic/s04_unknown_dependency.tsl"   "S04 Dependency on unknown task"     "unknown"
run_semantic "tests/semantic/s05_mixed_valid_circular.tsl" "S05 Mixed valid and circular tasks" "Circular"

# ═════════════════════════════════════════════════════════════
#  FINAL REPORT
# ═════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  TEST RESULTS SUMMARY${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "  Total  : ${BOLD}$TOTAL${RESET}"
echo -e "  Passed : ${GREEN}${BOLD}$PASS${RESET}"
echo -e "  Failed : ${RED}${BOLD}$FAIL${RESET}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}ALL TESTS PASSED ✓${RESET}"
else
    echo -e "  ${RED}${BOLD}$FAIL TEST(S) FAILED ✗${RESET}"
fi
echo ""
