%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── dependency graph for cycle detection ─────────────────── */
#define MAX_TASKS 64

typedef struct {
    char *name;
    char *depends_on;   /* NULL if no dependency */
} TaskEntry;

static TaskEntry task_table[MAX_TASKS];
static int       task_count = 0;

/* Register a task (and its optional dependency) */
static void register_task(const char *name, const char *dep) {
    if (task_count >= MAX_TASKS) {
        fprintf(stderr, "[Semantic Error] Too many tasks (max %d)\n", MAX_TASKS);
        return;
    }
    task_table[task_count].name       = strdup(name);
    task_table[task_count].depends_on = dep ? strdup(dep) : NULL;
    task_count++;
}

/* DFS-based cycle detection */
#define WHITE 0
#define GRAY  1
#define BLACK 2

static int color[MAX_TASKS];

static int find_task_index(const char *name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(task_table[i].name, name) == 0) return i;
    return -1;
}

static int dfs(int idx) {
    color[idx] = GRAY;
    const char *dep = task_table[idx].depends_on;
    if (dep) {
        int next = find_task_index(dep);
        if (next == -1) {
            fprintf(stderr,
                "[Semantic Error] Task '%s' depends on unknown task '%s'\n",
                task_table[idx].name, dep);
        } else if (color[next] == GRAY) {
            fprintf(stderr,
                "[Semantic Error] Circular dependency detected: '%s' -> '%s'\n",
                task_table[idx].name, dep);
            return 1;   /* cycle found */
        } else if (color[next] == WHITE) {
            if (dfs(next)) return 1;
        }
    }
    color[idx] = BLACK;
    return 0;
}

static void check_cycles(void) {
    memset(color, WHITE, sizeof(color));
    for (int i = 0; i < task_count; i++)
        if (color[i] == WHITE)
            if (dfs(i)) return;   /* stop at first cycle */
    printf("\n[Semantic Check] No circular dependencies found.\n");
}

/* ── forward declarations ─────────────────────────────────── */
void yyerror(const char *msg);
int  yylex(void);
extern int line_num;

/* ── per-task state, filled during parsing ────────────────── */
static char *current_task   = NULL;
static char *current_script = NULL;
static char *current_schedule = NULL;
static char *current_dep    = NULL;
static char *current_cond   = NULL;

static void reset_task_state(void) {
    free(current_task);     current_task     = NULL;
    free(current_script);   current_script   = NULL;
    free(current_schedule); current_schedule = NULL;
    free(current_dep);      current_dep      = NULL;
    free(current_cond);     current_cond     = NULL;
}

static void print_task(void) {
    printf("Executing Task: %s\n", current_task ? current_task : "?");
    printf("  Script: %s\n",   current_script   ? current_script   : "(none)");
    printf("  Schedule: %s\n", current_schedule ? current_schedule : "(none)");
    if (current_dep)  printf("  Depends on: %s\n", current_dep);
    if (current_cond) printf("  Condition: %s\n",  current_cond);
    printf("\n");
}
%}

/* ── semantic value type ──────────────────────────────────── */
%union {
    char *str;
}

/* ── token declarations ───────────────────────────────────── */
%token TASK RUN EVERY DAY WEEK ON AT AFTER BEFORE DEPENDS IF SUCCESS FAILURE
%token MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY SUNDAY
%token <str> IDENTIFIER STRING TIME

/* ── non-terminal types that carry string values ──────────── */
%type <str> weekday schedule_stmt condition_expr

%%

/* ═══════════════════════════════════════════════════════════
   program : one or more task definitions
   ═══════════════════════════════════════════════════════════ */
program
    : task_list
        {
            printf("--- EXECUTION COMPLETE ---\n");
            check_cycles();
        }
    ;

task_list
    : task_def
    | task_list task_def
    ;

/* ═══════════════════════════════════════════════════════════
   task_def : TASK <name> { task_body }
   ═══════════════════════════════════════════════════════════ */
task_def
    : TASK IDENTIFIER '{'
        {
            reset_task_state();
            current_task = strdup($2);
            free($2);
        }
      task_body '}'
        {
            print_task();
            register_task(current_task, current_dep);
        }
    ;

/* ═══════════════════════════════════════════════════════════
   task_body : run + optional schedule / dependency / condition
   The order is flexible: each clause is independently optional
   except RUN which is mandatory.
   ═══════════════════════════════════════════════════════════ */
task_body
    : run_stmt opt_clauses
    ;

run_stmt
    : RUN STRING
        {
            current_script = strdup($2);
            free($2);
        }
    ;

/* Zero or more optional clauses in any order */
opt_clauses
    : /* empty */
    | opt_clauses schedule_clause
    | opt_clauses dependency_clause
    | opt_clauses condition_clause
    ;

/* ── Schedule ─────────────────────────────────────────────── */
schedule_clause
    : schedule_stmt
        {
            current_schedule = $1;   /* $1 already strdup'd */
        }
    ;

schedule_stmt
    : EVERY DAY AT TIME
        {
            char buf[64];
            snprintf(buf, sizeof(buf), "EVERY DAY AT %s", $4);
            free($4);
            $$ = strdup(buf);
        }
    | EVERY WEEK ON weekday AT TIME
        {
            char buf[64];
            snprintf(buf, sizeof(buf), "EVERY WEEK ON %s AT %s", $4, $6);
            free($4); free($6);
            $$ = strdup(buf);
        }
    | AT TIME
        {
            char buf[32];
            snprintf(buf, sizeof(buf), "AT %s", $2);
            free($2);
            $$ = strdup(buf);
        }
    ;

weekday
    : MONDAY    { $$ = strdup("MONDAY");    }
    | TUESDAY   { $$ = strdup("TUESDAY");   }
    | WEDNESDAY { $$ = strdup("WEDNESDAY"); }
    | THURSDAY  { $$ = strdup("THURSDAY");  }
    | FRIDAY    { $$ = strdup("FRIDAY");    }
    | SATURDAY  { $$ = strdup("SATURDAY");  }
    | SUNDAY    { $$ = strdup("SUNDAY");    }
    ;

/* ── Dependency ───────────────────────────────────────────── */
dependency_clause
    : AFTER IDENTIFIER
        {
            current_dep = strdup($2);
            free($2);
        }
    | DEPENDS ON IDENTIFIER
        {
            current_dep = strdup($3);
            free($3);
        }
    | BEFORE IDENTIFIER
        {
            /* BEFORE means the *named* task depends on this one;
               we record it inversely for display purposes only */
            char buf[128];
            snprintf(buf, sizeof(buf), "(must finish before %s)", $2);
            current_dep = strdup(buf);
            free($2);
        }
    ;

/* ── Condition ────────────────────────────────────────────── */
condition_clause
    : IF condition_expr
        {
            current_cond = $2;
        }
    ;

condition_expr
    : SUCCESS { $$ = strdup("success"); }
    | FAILURE { $$ = strdup("failure"); }
    ;

%%

/* ── error handler ────────────────────────────────────────── */
void yyerror(const char *msg) {
    fprintf(stderr, "[Parse Error] Line %d: %s\n", line_num, msg);
}

/* ── entry point ──────────────────────────────────────────── */
int main(void) {
    printf("Parsing TaskLang++ input...\n\n");
    printf("--- EXECUTION START ---\n\n");
    yyparse();
    return 0;
}
