SRC_DIR:=src
BIN_DIR:=bin
SRC_FILES:=$(wildcard $(SRC_DIR)/*.asm)
TARGET=ispwriter

all: $(BIN_DIR)/$(TARGET).bin

$(BIN_DIR)/$(TARGET).bin: $(SRC_FILES) ../bootrom/bin/bootrom.bin
	@mkdir -p $(BIN_DIR)
	zasm -uy --z180 $(SRC_DIR)/$(TARGET).asm -l $(BIN_DIR)/$(TARGET).lst -o $(BIN_DIR)/$(TARGET).bin

clean:
	rm -f $(BIN_DIR)/$(TARGET).{lst,bin}
