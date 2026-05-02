# ─────────────────────────────────────────────
#  TaskLang++ Makefile
# ─────────────────────────────────────────────

CC      = gcc
CFLAGS  = -Wall -Wextra -g

TARGET  = tasklang

all: $(TARGET)

$(TARGET): parser.tab.c parser.tab.h lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.c lex.yy.c -lfl

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

# ── run all sample inputs ─────────────────────
test: $(TARGET)
	@echo "========================================"
	@echo "  TEST 1 – simple daily task"
	@echo "========================================"
	./$(TARGET) < samples/test1_simple.tsl
	@echo ""
	@echo "========================================"
	@echo "  TEST 2 – multi-step workflow"
	@echo "========================================"
	./$(TARGET) < samples/test2_workflow.tsl
	@echo ""
	@echo "========================================"
	@echo "  TEST 3 – weekly + condition"
	@echo "========================================"
	./$(TARGET) < samples/test3_weekly.tsl
	@echo ""
	@echo "========================================"
	@echo "  TEST 4 – circular dependency"
	@echo "========================================"
	./$(TARGET) < samples/test4_circular.tsl
	@echo ""
	@echo "========================================"
	@echo "  TEST 5 – INVALID (syntax error)"
	@echo "========================================"
	./$(TARGET) < samples/test5_invalid.tsl || true

clean:
	rm -f $(TARGET) parser.tab.c parser.tab.h lex.yy.c *.o

.PHONY: all test clean
