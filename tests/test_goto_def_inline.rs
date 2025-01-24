use aptos_move_analyzer::goto_definition::on_goto_definition;
use aptos_move_analyzer::project::Project;
use line_index::TextSize;
use std::fs;
use std::path::PathBuf;
use tempfile::TempDir;

fn test_aptos_project(package_root: PathBuf) -> Project {
    let project = Project::new(package_root, |_| {}).unwrap();
    assert!(project.load_ok(), "Cannot load");
    project
}

fn get_marked_position(source: &str, mark: &str) -> (u32, u32) {
    let offset = source.find(mark).unwrap() as u32;
    let file_index = line_index::LineIndex::new(source);
    let line_index::LineCol { line, col } = file_index.line_col(TextSize::new(offset));
    let ref_line = line - 1; // it's a //^ comment underneath the element
    let ref_col = col + 2; // we need a position of ^
    (ref_line, ref_col)
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
    assert!(
        !locations.is_empty(),
        "unresolved, locations = {:?}",
        locations
    );

    let actual_location = locations.first().unwrap().to_owned();
    let target_pos = lsp_types::Position::new(target_line, target_col);
    // todo: check for file
    assert!(is_inside_range(target_pos, actual_location.range));
}

#[rustfmt::skip]
#[cfg(test)]
mod tests {
    use super::*;

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
    fn test_resolve_function_in_use_stmt_with_numeric_address() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        public fun call() {}
                  //X
    }
    module 0x1::main {
        use 0x1::m::call;
                    //^
    }
        "#);
    }

    #[ignore = "resolution is not implemented for local use statements"]
    #[test]
    fn test_resolve_function_in_local_use_stmt() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
        public fun call() {}
                   //X
    }
    module std::main {
        fun main() {
            use std::m::call;
                        //^
        }
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

    #[test]
    fn test_resolve_module_self_in_use_group() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
        public fun call() {}
    }
    module std::main {
        use std::m::{Self, call};
                    //^
    }
        "#);
    }

    #[test]
    fn test_resolve_module_self_in_use_group_multiline() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
        public fun call() {}
    }
    module std::main {
        use std::m::{
            Self, call};
            //^
    }
        "#);
    }

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

    #[test]
    fn test_resolve_struct_field() {
        // language=Move
        test_resolve_reference(r#"
    module std::main {
        struct S { val: u8 }
                  //X
        fun main() {
            S { val: 1 }
                //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_struct_field_in_struct_pattern() {
        // language=Move
        test_resolve_reference(r#"
    module std::main {
        struct S { val: u8 }
                  //X
        fun main(s: S) {
            let S { val: myval } = s;
                  //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_struct_field_in_dot_expr() {
        // language=Move
        test_resolve_reference(r#"
    module std::main {
        struct S { val: u8 }
                  //X
        fun main() {
            let s = S { val: 1 };
            s.val;
              //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_const() {
        // language=Move
        test_resolve_reference(r#"
    module std::main {
        const MY_ERR: u8 = 1;
              //X
        fun main() {
            MY_ERR;
            //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_module_in_use_stmt() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
    }
    module std::main {
        use std::m;
               //^
    }
        "#);
    }

    #[test]
    fn test_resolve_module_in_use_item_stmt() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
        public fun call() {}
    }
    module std::main {
        use std::m::call;
               //^
    }
        "#);
    }

    #[ignore = "bug, i don't know"]
    #[test]
    fn test_resolve_module_in_qualified_ref() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
        public fun call() {}
    }
    module std::main {
        use std::m;
        fun main() {
            m::call();
          //^
        }
    }
        "#);
    }

    #[ignore = "bug, i don't know"]
    #[test]
    fn test_resolve_module_in_qualified_ref_with_self() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
              //X
        public fun call() {}
    }
    module std::main {
        use std::m::Self;
        fun main() {
            m::call();
          //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_module_item_in_qualified_ref() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
        public fun call() {}
                  //X
    }
    module std::main {
        use std::m;
        fun main() {
            m::call();
              //^
        }
    }
        "#);
    }

    #[test]
    fn test_resolve_module_item_in_qualified_ref_with_self() {
        // language=Move
        test_resolve_reference(r#"
    module std::m {
        public fun call() {}
                  //X
    }
    module std::main {
        use std::m::Self;
        fun main() {
            m::call();
              //^
        }
    }
        "#);
    }

    #[ignore = "not implemented"]
    #[test]
    fn test_resolve_module_spec() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
              //X
    }
    spec 0x1::m {
            //^
    }
        "#)
    }

    #[ignore = "not implemented"]
    #[test]
    fn test_resolve_function_spec() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        fun main() {}
            //X
    }
    spec 0x1::m {
        spec main {}
            //^
    }
        "#)
    }

    #[ignore = "not implemented?"]
    #[test]
    fn test_resolve_struct_spec() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        struct S { val: u8 }
             //X
    }
    spec 0x1::m {
        spec S {}
           //^
    }
        "#)
    }

    #[ignore = "not implemented"]
    #[test]
    fn test_resolve_function_call_inside_spec() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        fun main() {}
           //X
    }
    spec 0x1::m {
        spec main {
            main();
           //^
        }
    }
        "#)
    }

    #[ignore = "not implemented"]
    #[test]
    fn test_resolve_function_call_inside_spec_inside_module() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        fun call() {}
          //X
        public fun main() {
        }
        spec main {
            call();
           //^
        }
    }
        "#)
    }

    #[test]
    fn test_resolve_type_for_struct_field() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        struct S {
             //X
            val: u8
        }
        struct R {
            val: S
               //^
        }
    }
        "#)
    }

    #[test]
    fn test_resolve_type_for_struct_field_single_line() {
        // language=Move
        test_resolve_reference(r#"
    module 0x1::m {
        struct S { val: u8 }
             //X
        struct R { val: S }
                      //^
    }
        "#)
    }
}
