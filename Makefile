TARGET = FFHack.dylib
CC = clang++
CFLAGS = -arch arm64 -dynamiclib -O2 -mios-version-min=15.0 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -framework Foundation -framework CoreFoundation -framework UIKit

all: $(TARGET)

$(TARGET): FFHack.mm
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)
