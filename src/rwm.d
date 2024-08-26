import core.sys.windows.windows;
import core.sys.windows.psapi;
import core.sys.windows.winbase;
import core.stdc.stdlib : malloc, free;
import core.stdc.string : memcpy;
import core.memory : GC;
import std.conv : to;
import std.exception : enforce;
import std.string : format;
import std.typecons : Nullable;
import std.string : toStringz;
import std.format : format;
import std.algorithm : findSplit;

class AdvancedMemory {
    private:
        void* memBlock;
        size_t size;
        Nullable!string description;
        HANDLE hProcess = null;

    public:
        this(size_t size, Nullable!string description = Nullable!string.init) {
            this.size = size;
            this.memBlock = malloc(size);
            this.description = description;
            enforce(this.memBlock !is null, "Memory allocation failed");
        }

        this(string processName) {
            DWORD pid = getPIDByName(processName);
            enforce(pid != 0, "Failed to find process PID");
            this.hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
            enforce(this.hProcess !is null, "Failed to open process with PID: " ~ pid.to!string);
        }

        ~this() {
            if (this.memBlock !is null) {
                free(this.memBlock);
                this.memBlock = null;
            }
            if (this.hProcess !is null) {
                CloseHandle(this.hProcess);
            }
        }

        private DWORD getPIDByName(string processName) {
            DWORD[1024] processes;
            uint cbNeeded;

            if (!EnumProcesses(processes.ptr, processes.length * DWORD.sizeof, &cbNeeded))
                return 0;

            foreach (i; 0..cbNeeded / DWORD.sizeof) {
                HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, processes[i]);
                if (hProcess !is null) {
                    char[1024] processNameBuffer;
                    if (EnumProcessModules(hProcess, cast(HMODULE*)processes.ptr, DWORD.sizeof, &cbNeeded)) {
                        GetModuleBaseNameA(hProcess, processes.ptr[0], processNameBuffer.ptr, processNameBuffer.length);
                        if (processNameBuffer.to!string.split(".")[0].toLowercase() == processName.split(".")[0].toLowercase()) {
                            CloseHandle(hProcess);
                            return processes[i];
                        }
                    }
                    CloseHandle(hProcess);
                }
            }
            return 0;
        }

        void writeProcessMemory(T)(size_t address, T value) {
            enforce(this.hProcess !is null, "No process handle");
            enforce(WriteProcessMemory(this.hProcess, cast(void*)address, &value, T.sizeof, null), "Failed to write memory");
        }

        T readProcessMemory(T)(size_t address) {
            enforce(this.hProcess !is null, "No process handle");
            T value;
            enforce(ReadProcessMemory(this.hProcess, cast(void*)address, &value, T.sizeof, null), "Failed to read memory");
            return value;
        }

        void* getPointer() const {
            return this.memBlock;
        }

        size_t getSize() const {
            return this.size;
        }
        
        string getDescription() const {
            return this.description.isNull ? "No description" : this.description.get;
        }
}

void main() {
    auto mem = new AdvancedMemory("notepad.exe"); // Automatically attaches to the proccess 
    int newValue = 12345;
    mem.writeProcessMemory!int(0x7FF6345A0000, newValue);
    int readValue = mem.readProcessMemory!int(0x7FF6345A0000);
    writeln("Read value: ", readValue);
}
