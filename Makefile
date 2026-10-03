# ==============================================================================
# nosleep-mac Makefile
# ==============================================================================

APP_NAME := nosleep-mac
SRC := src/main.swift src/DurationParser.swift
BIN := $(APP_NAME)
SCRIPT := nosleep

# `make install` works without sudo. For a system-wide install, use:
# sudo make install PREFIX=/usr/local
PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

.PHONY: all build clean install uninstall status off test

all: build

build: $(BIN)

$(BIN): $(SRC)
	@echo "🔨 Building $(APP_NAME)..."
	swiftc -O -o $(BIN) $(SRC)
	@chmod +x $(SCRIPT)
	@echo "✅ Build completed: $(BIN)"

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f $(BIN)
	@echo "Done."

test:
	@mkdir -p .build
	@swiftc -o .build/duration-parser-tests src/DurationParser.swift tests/DurationParserTests.swift
	@.build/duration-parser-tests

status:
	@./$(SCRIPT) --status

off:
	@./$(SCRIPT) --off

install: build
	@echo "📦 Installing nosleep to $(BINDIR)..."
	@mkdir -p "$(BINDIR)"
	@install -m 755 "$(SCRIPT)" "$(BINDIR)/nosleep"
	@install -m 755 "$(BIN)" "$(BINDIR)/$(BIN)"
	@echo "✅ Installed: $(BINDIR)/nosleep"
	@echo "※ $(BINDIR) が PATH に含まれていることを確認してください。"

uninstall:
	@echo "🗑️  Uninstalling nosleep from $(BINDIR)..."
	@rm -f "$(BINDIR)/nosleep" "$(BINDIR)/$(BIN)"
	@echo "✅ Uninstalled."
