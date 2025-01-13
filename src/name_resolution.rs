use crate::ext::{from_ast_loc, LocExt};
use move_command_line_common::files::FileHash;
use move_compiler::diagnostics::Diagnostics;
use move_compiler::parser::ast::{Definition, ModuleIdent, ModuleMember, Use};
use move_compiler::shared::CompilationEnv;
use move_compiler::{parser, Flags, MatchedFileCommentMap};
use move_model::model::GlobalEnv;
use std::collections::BTreeSet;

fn parse_file_contents(
    file_contents: &str,
) -> Result<(Vec<Definition>, MatchedFileCommentMap), Diagnostics> {
    let mut env = CompilationEnv::new(Flags::empty(), BTreeSet::new());
    parser::syntax::parse_file_string(&mut env, FileHash::new(file_contents), file_contents)
}

#[derive(Debug)]
pub enum Reference {
    UseModule {
        module_ident: ModuleIdent,
    },
    UseItem {
        module_ident: ModuleIdent,
        item_name: move_compiler::shared::Name,
    },
    // Function(FunctionEnv<'a>),
    // Struct(StructEnv<'a>),
}

pub fn find_reference(
    env: &GlobalEnv,
    file_id: codespan::FileId,
    pos: (u32, u32),
) -> Option<Reference> {
    let contains_pos = |loc: move_ir_types::location::Loc| -> bool {
        from_ast_loc(file_id, loc).contains(env, pos)
    };

    let file_contents = env.get_file_source(file_id);
    let (top_level_defs, _comments_map) = parse_file_contents(file_contents).ok()?;

    let module = top_level_defs
        .iter()
        .filter_map(|def| match def {
            Definition::Module(module) => Some(module),
            // todo: only module for now
            _ => None,
        })
        .find(|module| contains_pos(module.loc))?;

    for member in module.members.iter() {
        match member {
            ModuleMember::Use(use_decl) => {
                match &use_decl.use_ {
                    // todo: don't handle aliases for now
                    Use::Module(module_ident, _) => {
                        if contains_pos(module_ident.loc) {
                            return Some(Reference::UseModule {
                                module_ident: module_ident.clone(),
                            });
                        }
                    }
                    Use::Members(module_ident, members) => {
                        if contains_pos(module_ident.loc) {
                            return Some(Reference::UseModule {
                                module_ident: module_ident.clone(),
                            });
                        }
                        for (member_name, _) in members {
                            if contains_pos(member_name.loc) {
                                return Some(Reference::UseItem {
                                    module_ident: module_ident.clone(),
                                    item_name: member_name.clone(),
                                });
                            }
                        }
                    }
                }
            }
            _ => return None,
        }
    }

    None
}
