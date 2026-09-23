# ==============================================================================
# nosleep-mac Makefile
# ==============================================================================

APP_NAME = nosleep-mac
SRC = src/main.swift src/DurationParser.swift
BIN = $(APP_NAME)
SCRIPT = nosleep

PREFIX ?= /usr/local
USER_PREFIX = $(HOME)/.local

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
	@echo "📦 Installing nosleep..."
	@if [ -w "$(PREFIX)/bin" ]; then \
		ln -sf "$(CURDIR)/$(SCRIPT)" "$(PREFIX)/bin/nosleep"; \
		echo "✅ Installed to $(PREFIX)/bin/nosleep"; \
	elif [ -d "$(USER_PREFIX)/bin" ]; then \
		ln -sf "$(CURDIR)/$(SCRIPT)" "$(USER_PREFIX)/bin/nosleep"; \
		echo "✅ Installed to $(USER_PREFIX)/bin/nosleep"; \
		echo "※ $(USER_PREFIX)/bin が PATH に含まれていることを確認してください。"; \
	else \
		mkdir -p "$(USER_PREFIX)/bin"; \
		ln -sf "$(CURDIR)/$(SCRIPT)" "$(USER_PREFIX)/bin/nosleep"; \
		echo "✅ Installed to $(USER_PREFIX)/bin/nosleep"; \
		echo "💡 ヒント: ~/.zshrc に以下を追加するとどこからでも実行できます:"; \
		echo '    export PATH="$$HOME/.local/bin:$$PATH"'; \
	fi

uninstall:
	@echo "🗑️  Uninstalling nosleep..."
	@rm -f "$(PREFIX)/bin/nosleep" "$(USER_PREFIX)/bin/nosleep"
	@echo "✅ Uninstalled successfully."
