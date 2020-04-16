BUILD_DIR=.

CC = gcc

CFLAGS = -O2 -Wall
LDFLAGS = 
SHARED = -fPIC --shared

CLUALIB = ltimer

CLUALIB_TARGET = $(patsubst %, $(BUILD_DIR)/%.so,$(CLUALIB))

all:$(CLUALIB_TARGET)

#clualib begin
$(BUILD_DIR)/ltimer.so:src/lua-twheel.c src/twheel.c 
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS)

#clualib end

clean:
	rm -f $(CLUALIB_TARGET)