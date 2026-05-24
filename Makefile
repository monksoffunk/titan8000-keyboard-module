KEYBOARD_NAME		:= titan8000
SHIELD_STR			:="$(KEYBOARD_NAME) "
DEFAULT_TARGET_DIR 	:= build/$(KEYBOARD_NAME)/zephyr
DEFAULT_TARGET		:= $(DEFAULT_TARGET_DIR)/zmk.uf2
BOARD1				:= xiao_ble_plus
BOARD2				:= xiao_rp2040
TARGET1				:= $(KEYBOARD_NAME)_$(BOARD1).uf2
TARGET2				:= $(KEYBOARD_NAME)_$(BOARD2).uf2
DEBUG_TARGET1		:= $(KEYBOARD_NAME)_$(BOARD1)_debug.uf2
DEBUG_TARGET2		:= $(KEYBOARD_NAME)_$(BOARD2)_debug.uf2

# ===== Python venv management =====

VENV_DIR := .venv
PYTHON   := python3
PIP      := $(VENV_DIR)/bin/pip
ACTIVATE := . $(VENV_DIR)/bin/activate
WEST     := $(VENV_DIR)/bin/west

# Ensure subprocesses spawned by west/cmake/ninja resolve python tools from venv first.
export PATH := $(abspath $(VENV_DIR))/bin:$(PATH)

WEST_MANIFEST_DIR     := config
ZEPHYR_BASE_REQ       := zephyr/scripts/requirements-base.txt
ZEPHYR_EXTRAS_REQ     := zephyr/scripts/requirements-extras.txt
WEST_STAMP            := .west/.updated
ZEPHYR_DEPS_STAMP     := $(VENV_DIR)/.zephyr_deps_installed
ZEPHYR_EXTRAS_STAMP   := $(VENV_DIR)/.zephyr_extras_installed
NANOPB_PROTOC_WRAPPER := $(abspath tools/protoc_python_wrapper.sh)
EXTRA_CMAKE_ARGS      ?=
CMAKE_ARGS            := -DSHIELD=titan8000 -DPROTOBUF_PROTOC_EXECUTABLE=$(NANOPB_PROTOC_WRAPPER) $(EXTRA_CMAKE_ARGS)

all	: setup $(TARGET1) $(TARGET2) 

debug: setup $(DEBUG_TARGET1) $(DEBUG_TARGET2)

venv:
	@test -d $(VENV_DIR) || $(PYTHON) -m venv $(VENV_DIR)
	@$(PIP) install --upgrade pip

deps: venv
	@$(PIP) install -r requirements.txt
	@$(PIP) install -U west

$(WEST_STAMP): deps
	@test -d .west || $(WEST) init -l $(WEST_MANIFEST_DIR)
	@$(WEST) update
	@touch $(WEST_STAMP)

zephyr-export: $(WEST_STAMP)
	@$(WEST) zephyr-export

$(ZEPHYR_DEPS_STAMP): $(WEST_STAMP)
	@$(PIP) install -r $(ZEPHYR_BASE_REQ)
	@touch $(ZEPHYR_DEPS_STAMP)

$(ZEPHYR_EXTRAS_STAMP): $(ZEPHYR_DEPS_STAMP)
	@$(PIP) install -r $(ZEPHYR_EXTRAS_REQ)
	@touch $(ZEPHYR_EXTRAS_STAMP)

setup: zephyr-export $(ZEPHYR_DEPS_STAMP)

setup-studio: setup $(ZEPHYR_EXTRAS_STAMP)

pip-list: venv
	@$(PIP) list

shell: venv
	@bash -c '$(ACTIVATE) && exec $$SHELL -i'

venv-clean:
	@rm -rf $(VENV_DIR)

$(TARGET1):
	$(WEST) build -s zmk/app -b seeeduino_xiao_ble -d build/titan8000 -S studio-rpc-usb-uart -p always -- $(CMAKE_ARGS)
	mv $(DEFAULT_TARGET) $(TARGET1)

$(TARGET2):
	$(WEST) build -s zmk/app -b seeeduino_xiao_rp2040 -d build/titan8000  -S studio-rpc-usb-uart -p always -- $(CMAKE_ARGS)
	mv $(DEFAULT_TARGET) $(TARGET2)

$(DEBUG_TARGET1):
	$(WEST) build -s zmk/app -b seeeduino_xiao_ble -d build/titan8000 -S zmk-usb-logging -p always -- $(CMAKE_ARGS)
	mv $(DEFAULT_TARGET) $(DEBUG_TARGET1)	

$(DEBUG_TARGET2):
	$(WEST) build -s zmk/app -b seeeduino_xiao_rp2040 -d build/titan8000  -S zmk-usb-logging -p always -- $(CMAKE_ARGS)
	mv $(DEFAULT_TARGET) $(DEBUG_TARGET2)

clean:
	@rm -rf build

fclean: clean
	@rm -f $(TARGET1) $(TARGET2)
	@rm -f $(DEBUG_TARGET1) $(DEBUG_TARGET2)
	@rm -f $(WEST_STAMP) $(ZEPHYR_DEPS_STAMP) $(ZEPHYR_EXTRAS_STAMP)

re: fclean all

.PHONY: all re clean fclean venv venv-clean deps zephyr-export setup setup-studio pip-list shell
