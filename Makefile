
MAIN_MOD=JSON::Class
META_MOD=$(MAIN_MOD)
BUILD_TOOLS_DIR=./build-tools
README_SRC = $(DOC_SRC_DIR)/JSON/Class.rakudoc
NO_META6=yes

include $(BUILD_TOOLS_DIR)/makefile.inc
