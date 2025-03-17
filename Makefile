.PHONY: all build clean rebuild start compile_asm compile_c

PROJECT_NAME = printf_nasm

BUILD_DIR = ./build
SRC_DIR = ./src
ASM_COMPILER = nasm
C_COMPILER = gcc
LINKER = ld
SYSTEM = elf64

FLAGS += $(ADD_FLAGS)

DIRS = 
BUILD_DIRS = $(DIRS:%=$(BUILD_DIR)/%)

SOURCES_ASM = printme.asm
SOURCES_C	= main.c

SOURCES_ASM_REL_PATH = $(SOURCES_ASM:%=$(SRC_DIR)/%)
OBJECTS_ASM_REL_PATH = $(SOURCES_ASM:%.asm=$(BUILD_DIR)/%.o)
LISTINGS_ASM_REL_PATH = $(SOURCES_ASM:%.asm=$(BUILD_DIR)/%.lst)

SOURCES_C_REL_PATH = $(SOURCES_C:%=./$(SRC_DIR)/%)
OBJECTS_C_REL_PATH = $(SOURCES_C:%.c=$(BUILD_DIR)/%.o)

all: build start

rebuild: clean_all build

start: 
	./$(PROJECT_NAME).out $(OPTS)

build: $(PROJECT_NAME).out



$(PROJECT_NAME).out: compile_asm compile_c
	$(C_COMPILER) $(FLAGS) -o $@ $(OBJECTS_C_REL_PATH) $(OBJECTS_ASM_REL_PATH) -lm

compile_asm: $(SOURCES_ASM_REL_PATH) | ./$(BUILD_DIR)/ $(BUILD_DIRS)
	$(ASM_COMPILER) $(FLAGS) -f $(SYSTEM) -l $(LISTINGS_ASM_REL_PATH) -o $(OBJECTS_ASM_REL_PATH) $(SOURCES_ASM_REL_PATH)

compile_c: $(SOURCES_C_REL_PATH) | ./$(BUILD_DIR)/ $(BUILD_DIRS)
	$(C_COMPILER) $(FLAGS) -o $(OBJECTS_C_REL_PATH) -c $(SOURCES_C_REL_PATH)
	

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