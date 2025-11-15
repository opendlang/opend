module test_runner;

import std.stdio;
import std.traits;
import std.meta;

// ============================================================================
// UNIT TEST INTROSPECTION TRAITS
// ============================================================================

/**
 * Get all unit test functions from a module or type
 */
template getUnitTests(alias T) {
    alias getUnitTests = __traits(getUnitTests, T);
}

/**
 * Get unit test names from a module or type
 */
template getUnitTestNames(alias T) {
    import std.meta : staticMap;
    
    alias tests = getUnitTests!T;
    
    template GetName(alias test) {
        enum GetName = __traits(getUnitTestName, test);
    }
    
    alias getUnitTestNames = staticMap!(GetName, tests);
}

/**
 * Check if a symbol has any unit tests
 */
template hasUnitTests(alias T) {
    enum hasUnitTests = getUnitTests!T.length > 0;
}

/**
 * Get the number of unit tests for a symbol
 */
template unitTestCount(alias T) {
    enum unitTestCount = getUnitTests!T.length;
}

// ============================================================================
// PATTERN MATCHING (GTEST-STYLE FILTERING)
// ============================================================================

/**
 * Simple wildcard pattern matching (gtest-style)
 * Supports: * (any chars), ? (single char), exact match
 */
bool matchesPattern(string text, string pattern) {
    import std.algorithm : canFind;
    
    if (pattern == "*") return true;
    if (pattern == text) return true;
    if (pattern.canFind('*') || pattern.canFind('?')) {
        return matchWildcard(text, pattern);
    }
    return false;
}

private bool matchWildcard(string text, string pattern) {
    if (pattern.length == 0) return text.length == 0;
    if (text.length == 0) return pattern == "*";
    
    if (pattern[0] == '*') {
        // Try matching rest of pattern at each position in text
        for (size_t i = 0; i <= text.length; i++) {
            if (matchWildcard(text[i..$], pattern[1..$])) {
                return true;
            }
        }
        return false;
    } else {
        // Character must match (including ? wildcard)
        if (pattern[0] == text[0] || pattern[0] == '?') {
            return matchWildcard(text[1..$], pattern[1..$]);
        }
        return false;
    }
}

// ============================================================================
// TEST EXECUTION FUNCTIONS
// ============================================================================

/**
 * Run a specific unit test by name
 */
void runUnitTestByName(alias T, string testName)() {
    alias tests = getUnitTests!T;
    alias names = getUnitTestNames!T;
    
    static foreach (i; 0 .. tests.length) {
        static if (names[i] == testName) {
            writeln("Running test: ", testName);
            executeTest(tests[i], testName);
        }
    }
}

/**
 * Execute a single test with proper error handling
 */
private void executeTest(alias testFunc, string testName)() {
    try {
        testFunc();
        writeln("✓ Test '", testName, "' PASSED");
    } catch (Throwable e) {  // Need Throwable to catch AssertError
        writeln("✗ Test '", testName, "' FAILED: ", e.msg);
    }
}

// ============================================================================
// CLI INTERFACE
// ============================================================================

void printUsage() {
    writeln("OpenD Advanced Test Runner");
    writeln("Usage (via opend):");
    writeln("  opend test list                        - List all available unit tests");
    writeln("  opend test run <test_name>             - Run a specific unit test");
    writeln("  opend test                             - Run all unit tests");
    writeln("  opend test filter <pattern>            - Run tests matching pattern");
    writeln("  opend test --help                      - Show this help message");
    writeln();
    writeln("Filter patterns (gtest-style):");
    writeln("  *        - Match any characters");
    writeln("  ?        - Match single character");
    writeln("  H*       - Tests starting with 'H'");
    writeln("  *Test    - Tests ending with 'Test'");
    writeln("  *Math*   - Tests containing 'Math'");
    writeln("  H??      - 3-character tests starting with 'H'");
    writeln();
    writeln("Examples:");
    writeln("  opend test filter \"H*\"               - Run tests starting with 'H'");
    writeln("  opend test filter \"*Test\"            - Run tests ending with 'Test'");
    writeln("  opend test run \"MyModule\"            - Run tests in MyModule");
}

void listTests() {
    writeln("=== Available Unit Tests ===\n");
    
    version(unittest) {
        // Get tests from all modules
        import std.meta : AliasSeq;
        
        // Try to get tests from the current module and any imported user modules
        mixin("import " ~ __MODULE__ ~ ";");
        
        // For now, let's make this work with any module that imports this
        // We'll need runtime reflection to get all modules with tests
        listTestsFromCurrentProgram();
    } else {
        writeln("Unit tests not compiled in. Compile with -unittest flag.");
    }
}

private void listTestsFromCurrentProgram() {
    import core.runtime : Runtime, ModuleInfo;
    
    int totalTests = 0;
    
    foreach (m; Runtime.moduleinfos) {
        if (m is null || m.unitTest is null) continue;
        
        writeln("Module: ", m.name);
        writeln("Has unit tests");
        totalTests++;
    }
    
    if (totalTests == 0) {
        writeln("No unit tests found in any loaded modules.");
    } else {
        writeln("\nFound unit tests in ", totalTests, " modules.");
        writeln("Note: Use D's built-in unittest runner or compile with specific modules for detailed test names.");
    }
}

void runAllTests() {
    writeln("=== Running All Unit Tests ===\n");
    
    version(unittest) {
        runAllTestsFromCurrentProgram();
    } else {
        writeln("Unit tests not compiled in. Compile with -unittest flag.");
    }
}

private void runAllTestsFromCurrentProgram() {
    import core.runtime : Runtime, ModuleInfo;
    
    int totalPassed = 0, totalFailed = 0, totalModules = 0;
    
    foreach (m; Runtime.moduleinfos) {
        if (m is null || m.unitTest is null) continue;
        
        totalModules++;
        writeln("Running tests in module: ", m.name);
        
        try {
            m.unitTest()();
            writeln("  ✓ Module tests PASSED\n");
            totalPassed++;
        } catch (Exception e) {
            writeln("  ✗ Module tests FAILED: ", e.msg, "\n");
            totalFailed++;
        } catch (Error e) {
            writeln("  ✗ Module tests ERROR: ", e.msg, "\n");
            totalFailed++;
        }
    }
    
    writeln("=== Summary ===");
    writeln("Total modules with tests: ", totalModules);
    writeln("Modules passed: ", totalPassed);  
    writeln("Modules failed: ", totalFailed);
    
    if (totalModules == 0) {
        writeln("No unit tests found in any loaded modules.");
    }
}

void runFilteredTests(string pattern) {
    writeln("=== Running Tests Matching Pattern: '", pattern, "' ===\n");
    
    version(unittest) {
        writeln("Pattern-based filtering is currently limited in D's runtime reflection.");
        writeln("Pattern: ", pattern);
        writeln("Running all tests from modules matching the pattern...\n");
        
        runFilteredTestsFromCurrentProgram(pattern);
    } else {
        writeln("Unit tests not compiled in. Compile with -unittest flag.");
    }
}

private void runFilteredTestsFromCurrentProgram(string pattern) {
    import core.runtime : Runtime, ModuleInfo;
    import std.algorithm : canFind;
    
    int totalPassed = 0, totalFailed = 0, matchedModules = 0;
    
    foreach (m; Runtime.moduleinfos) {
        if (m is null || m.unitTest is null) continue;
        
        // Simple pattern matching on module name
        if (matchesPattern(m.name, pattern)) {
            matchedModules++;
            writeln("Running tests in matching module: ", m.name);
            
            try {
                m.unitTest()();
                writeln("  ✓ Module tests PASSED\n");
                totalPassed++;
            } catch (Exception e) {
                writeln("  ✗ Module tests FAILED: ", e.msg, "\n");
                totalFailed++;
            } catch (Error e) {
                writeln("  ✗ Module tests ERROR: ", e.msg, "\n");
                totalFailed++;
            }
        }
    }
    
    writeln("=== Filter Results ===");
    writeln("Pattern: ", pattern);
    writeln("Matched modules: ", matchedModules);
    writeln("Modules passed: ", totalPassed);
    writeln("Modules failed: ", totalFailed);
    
    if (matchedModules == 0) {
        writeln("\nNo modules matched pattern '", pattern, "'");
        writeln("Available modules with tests:");
        foreach (m; Runtime.moduleinfos) {
            if (m !is null && m.unitTest !is null) {
                writeln("  - ", m.name);
            }
        }
    }
}

void runSpecificTest(string testName) {
    writeln("=== Running Specific Test: '", testName, "' ===\n");
    
    version(unittest) {
        writeln("Running specific named tests requires compile-time module information.");
        writeln("Attempting to run tests from module: ", testName, "\n");
        
        runSpecificTestFromCurrentProgram(testName);
    } else {
        writeln("Unit tests not compiled in. Compile with -unittest flag.");
    }
}

private void runSpecificTestFromCurrentProgram(string testName) {
    import core.runtime : Runtime, ModuleInfo;
    import std.algorithm : canFind, endsWith;
    
    bool found = false;
    
    foreach (m; Runtime.moduleinfos) {
        if (m is null || m.unitTest is null) continue;
        
        // Try to match module name or if testName matches module name
        if (m.name == testName || m.name.endsWith("." ~ testName) || testName.endsWith(m.name)) {
            found = true;
            writeln("Running tests in module: ", m.name);
            
            try {
                m.unitTest()();
                writeln("✓ Test module '", m.name, "' PASSED");
            } catch (Exception e) {
                writeln("✗ Test module '", m.name, "' FAILED: ", e.msg);
            } catch (Error e) {
                writeln("✗ Test module '", m.name, "' ERROR: ", e.msg);
            }
            break;
        }
    }
    
    if (!found) {
        writeln("Module or test '", testName, "' not found!");
        writeln("Use 'list' command to see available test modules.");
    }
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

/**
 * Custom entry point that bypasses D's automatic unittest execution
 * This allows us to run tests selectively instead of all at once
 */
extern(C) int main(int argc, char** argv) @trusted {
    import std.conv : to;
    import core.runtime : Runtime;
    
    Runtime.initialize();
    
    // Convert C-style args to D-style
    string[] args;
    for (int i = 0; i < argc; i++) {
        import core.stdc.string : strlen;
        args ~= argv[i][0..strlen(argv[i])].idup;
    }
    
    dmain(args);
    
    Runtime.terminate();
    return 0;
}

/**
 * Main CLI dispatcher
 */
void dmain(string[] args) {
    if (args.length < 2) {
        printUsage();
        return;
    }
    
    switch (args[1]) {
        case "list":
            listTests();
            break;
            
        case "run":
            if (args.length < 3) {
                writeln("Error: Please specify a test name.");
                writeln("Usage: ./unittest_cli run <test_name>");
                return;
            }
            runSpecificTest(args[2]);
            break;
            
        case "run-all":
            runAllTests();
            break;
            
        case "filter":
            if (args.length < 3) {
                writeln("Error: Please specify a filter pattern.");
                writeln("Usage: ./unittest_cli filter <pattern>");
                writeln("Example: ./unittest_cli filter \"H*\"");
                return;
            }
            runFilteredTests(args[2]);
            break;
            
        case "help", "--help", "-h":
            printUsage();
            break;
            
        default:
            writeln("Unknown command: ", args[1]);
            printUsage();
            break;
    }
}