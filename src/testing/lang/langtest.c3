//-----------------------------------------------------------------------------
// punk language test cases
//-----------------------------------------------------------------------------
module punk::testing::lang;

//-----------------------------------------------------------------------------
// ENUMERATIONS
//-----------------------------------------------------------------------------

enum CaseKind { VALUE }

//-----------------------------------------------------------------------------
// STRUCTURES
//-----------------------------------------------------------------------------

struct CaseSpec {
    String name;
    String path;
    CaseKind kind;
}

struct TestSession {
    inline Session session;
}


//-----------------------------------------------------------------------------
// FUNCTIONS
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
fn CaseSpec value_case(String name, String path) {
    return { .name = name, .path = path, .kind = VALUE };
}


//-----------------------------------------------------------------------------
fn int run_lang_tests() {
    String math = "test/lang/math.punk";
    
    CaseSpec[*] cases = {
        value_case("math/basic", math),
    };

    if (catch err = execute_cases(&cases)) {
        return 1;
    }
    return 0;
}


//-----------------------------------------------------------------------------
fn void? execute_cases(CaseSpec[] cases) {

    // for each case,
    // - load file fresh
    // - create compiler
    // - append instruction for running specific case
    // - create testing vm

    TestSession s;

    // init session
    s.diagnostics.info("Initializing Test Session");
    s.platform.init_headless(&s.diagnostics)!;


    String path = cases[0].path;
    s.diagnostics.file_path = path;
    bool loaded = true;
    if (catch err = s.platform.load_cart(&s.cart, path)) {
        loaded = false;
    }
    
    if (loaded) {
        if (catch err = s.platform.vm.dispatch_global()) {
        }

        if (catch err = s.platform.vm.dispatch_if_defined("start")) {
        }
    }

    s.diagnostics.report();
    s.diagnostics.destroy();

}