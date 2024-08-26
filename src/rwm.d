import core.stdc.stdlib : malloc, free;
import core.stdc.string : memcpy;
import core.memory : GC;
import std.conv : to;
import std.exception : enforce;
import std.string : format;
import std.typecons : Nullable;

class AdvancedMemory {
    private:
        void* memBlock;
        size_t size;
        Nullable!string description;

    public:
        this(size_t size, Nullable!string description = Nullable!string.init) {
            this.size = size;
            this.memBlock = malloc(size);
            this.description = description;
            enforce(this.memBlock !is null, "[ERR] Memory allocation failed");
        }

        ~this() {
            if (this.memBlock !is null) {
                free(this.memBlock);
                this.memBlock = null;
            }
        }

        void write(T)(size_t offset, T value) {
            static assert(is(T == class) || is(T == struct), "[ERR] Only class or struct types are allowed");
            enforce(offset + T.sizeof <= this.size, "[ERR] Write out of bounds");

            void* dest = cast(void*) (cast(ubyte*) this.memBlock + offset);
            memcpy(dest, &value, T.sizeof);
        }

        T read(T)(size_t offset) {
            static assert(is(T == class) || is(T == struct), "[ERR] Only class or struct types are allowed");
            enforce(offset + T.sizeof <= this.size, "[ERR] Read out of bounds");

            T value;
            void* src = cast(void*) (cast(ubyte*) this.memBlock + offset);
            memcpy(&value, src, T.sizeof);
            return value;
        }

        void obfuscate() {
            ubyte* ptr = cast(ubyte*) this.memBlock;
            for (size_t i = 0; i < this.size; i++) {
                ptr[i] ^= 0xFF;
            }
        }

        void deobfuscate() {
            obfuscate();
        }
        
        void* getPointer() const {
            return this.memBlock;
        }

        size_t getSize() const {
            return this.size;
        }
        
        string getDescription() const {
            return this.description.isNull ? "[ERR] No description" : this.description.get;
        }
}

void main() {
    auto mem = new AdvancedMemory(1024, "Test Memory Block");

    struct TestStruct {
        int a;
        float b;
    }

    TestStruct testValue = TestStruct(42, 3.14);
    mem.write(0, testValue);

    TestStruct readValue = mem.read!TestStruct(0);
    assert(readValue.a == 42 && readValue.b == 3.14);

    mem.obfuscate();
    mem.deobfuscate();
}
