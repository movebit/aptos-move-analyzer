use aptos_move_analyzer::goto_definition::on_goto_definition;
use aptos_move_analyzer::project::Project;
use std::fs;
use std::path::PathBuf;
use tempfile::TempDir;

fn test_aptos_project(package_root: PathBuf) -> Project {
    let project = Project::new(package_root, |_| {}).unwrap();
    assert!(project.load_ok(), "Cannot load");
    project
}

fn get_marked_position(source: &str, mark: &str) -> (u32, u32) {
    let offset = source.find(mark).unwrap();
    let (line, col) = line_col::LineColLookup::new(&source).get(offset);
    let ref_line = line - 1; // it's a //^ comment underneath the element
    let ref_col = col + 2; // we need a position of ^
                           // it's zero based
    ((ref_line - 1) as u32, (ref_col - 1) as u32)
}

fn is_inside_range(pos: lsp_types::Position, range: lsp_types::Range) -> bool {
    range.start <= pos && pos <= range.end
}

fn move_test_package(temp_dir: &TempDir, main_source: &str) -> PathBuf {
    let package_root = temp_dir.path().to_path_buf();
    fs::create_dir(package_root.join("sources")).unwrap();
    fs::write(
        package_root.join("Move.toml"),
        // language=Toml
        r#"
[package]
name = "MyTestPackage"
version = "1.0.0"
authors = []

[addresses]
std = "0x1"
        "#,
    )
    .unwrap();
    fs::write(
        package_root.join("sources").join("main.move"),
        main_source.trim_start(),
    )
    .unwrap();
    package_root
}

fn test_resolve_reference(main_source: &str) {
    let temp = tempfile::tempdir().unwrap();
    let package_root = move_test_package(&temp, main_source);
    let aptos_project = test_aptos_project(package_root.clone());

    let source_fpath = package_root.join("sources").join("main.move");
    let source = fs::read_to_string(source_fpath.clone()).unwrap();

    let (ref_line, ref_col) = get_marked_position(&source, "//^");
    let (target_line, target_col) = get_marked_position(&source, "//X");

    let locations = on_goto_definition(&aptos_project, source_fpath, ref_line, ref_col);
    assert!(!locations.is_empty(), "unresolved, locations = {:?}", locations);

    let actual_location = locations.first().unwrap().to_owned();
    let target_pos = lsp_types::Position::new(target_line, target_col);
    // todo: check for file
    assert!(is_inside_range(target_pos, actual_location.range));
}

#[test]
fn test_resolve_function_call() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    fun call() {}
       //X
    fun main() {
        call();
         //^
    }
}
    "#);
}

#[test]
fn test_resolve_function_call_another_module() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    public fun call() {}
               //X
}
module std::main {
    use std::m::call;
    fun main() {
        call();
         //^
    }
}
    "#);
}

#[test]
fn test_resolve_function_in_use_stmt() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    public fun call() {}
               //X
}
module std::main {
    use std::m::call;
                //^
}
    "#);
}

#[test]
fn test_resolve_function_in_use_group() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    public fun call() {}
               //X
}
module std::main {
    use std::m::{call};
                //^
}
    "#);
}

#[ignore = "resolution is not implemented for multiline use groups yet"]
#[test]
fn test_resolve_function_in_use_group_on_separate_line() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    public fun call() {}
               //X
}
module std::main {
    use std::m::{
        call
      //^
    };
}
    "#);
}

#[test]
fn test_resolve_struct_from_use_stmt() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    struct S { val: u8 }
         //X
}
module std::main {
    use std::m::S;
              //^
}
    "#);
}

#[test]
fn test_resolve_struct_from_type() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    struct S { val: u8 }
         //X
    fun main(): S {
              //^
    }
}
    "#);
}

#[test]
fn test_resolve_struct_from_type_another_module() {
    // language=Move
    test_resolve_reference(r#"
module std::m {
    struct S { val: u8 }
         //X
}
module std::main {
    use std::m::S;
    fun main(): S {
              //^
    }
}
    "#);
}

#[ignore = "bug, single line functions are broken"]
#[test]
fn test_resolve_struct_from_type_single_line_function() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    struct S { val: u8 }
         //X
    fun main(): S {}
              //^
}
    "#);
}

#[test]
fn test_resolve_struct_from_struct_literal() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    struct S { val: u8 }
         //X
    fun main() {
        S { val: 1 };
      //^
    }
}
    "#);
}

#[ignore = "bug, stmt on the same line as the end of outer block"]
#[test]
fn test_resolve_struct_from_struct_literal_single_line() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    struct S { val: u8 }
         //X
    fun main() {
        S { val: 1 }; }
      //^
}
    "#);
}

#[test]
fn test_resolve_struct_from_function_parameter_type() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    struct S { val: u8 }
         //X
    fun main(s: S) {
              //^
    }
}
    "#);
}

#[test]
fn test_resolve_function_parameter() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    fun main(s: u8) {
           //X
        s;
      //^
    }
}
    "#);
}

#[test]
fn test_resolve_variable() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    fun main() {
        let s = 1;
          //X
        s;
      //^
    }
}
    "#);
}

#[test]
fn test_resolve_variable_with_parameter_shadowing() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    fun main(s: u8) {
        let s = 1;
          //X
        s;
      //^
    }
}
    "#);
}

#[test]
fn test_resolve_variable_with_another_variable_shadowing() {
    // language=Move
    test_resolve_reference(r#"
module std::main {
    fun main(s: u8) {
        let s = 1;
        let s = 2;
          //X
        s;
      //^
    }
}
    "#);
}


