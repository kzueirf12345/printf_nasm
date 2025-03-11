.PHONY: all build clean rebuild start

PROJECT_NAME = printf_nasm

BUILD_DIR = ./build
SRC_DIR = ./src
COMPILER = nasm
LINKER = ld
SYSTEM = elf64

FLAGS += $(ADD_FLAGS)

DIRS = 
BUILD_DIRS = $(DIRS:%=$(BUILD_DIR)/%)

SOURCES = main.asm

SOURCES_REL_PATH = $(SOURCES:%=./$(SRC_DIR)/%)
OBJECTS_REL_PATH = $(SOURCES:%.asm=$(BUILD_DIR)/%.o)
LISTINGS_REL_PATH = $(SOURCES:%.asm=$(BUILD_DIR)/%.lst)

all: build start

start: 
	./$(PROJECT_NAME).out $(OPTS)

build: $(PROJECT_NAME).out

rebuild: clean_all build


$(PROJECT_NAME).out: $(OBJECTS_REL_PATH)
	$(LINKER) $(FLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | ./$(BUILD_DIR)/ $(BUILD_DIRS)
	nasm $(FLAGS) -f $(SYSTEM) -l $(LISTINGS_REL_PATH) -o $@ $^

$(BUILD_DIRS):
	mkdir $@
./$(BUILD_DIR)/:
	mkdir $@

clean_all: clean_o clean_out clean_lst

clean_o:
	rm -rf ./*.o

clean_out:
	rm -rf ./*.out

clean_lst:
	rm -rf ./*.lst