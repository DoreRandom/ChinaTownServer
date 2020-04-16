BUILD_DIR=../build

BUILD_LUACLIB_DIR=$(BUILD_DIR)/luaclib

CLUALIB = ltimer cjson protobuf

CLUALIB_TARGET = $(patsubst %, $(BUILD_LUACLIB_DIR)/%.so,$(CLUALIB))

all:$(CLUALIB)

#clualib begin
ltimer:
	make -C ./timewheel
	mv ./timewheel/ltimer.so $(BUILD_LUACLIB_DIR)/ltimer.so

cjson:
	make -C ./lua-cjson
	mv ./lua-cjson/cjson.so $(BUILD_LUACLIB_DIR)/cjson.so

protobuf:
	make -C ./pbc
	make -C ./pbc/binding/lua53
	mv ./pbc/binding/lua53/protobuf.so $(BUILD_LUACLIB_DIR)/protobuf.so

#clualib end

clean:

	rm -f $(CLUALIB_TARGET)

cleanall:
	#clean all
	make clean -C ./timewheel
	make clean -C ./lua-cjson
	make clean -C ./pbc
	make clean -C ./pbc/binding/lua53
	rm -f $(CLUALIB_TARGET)