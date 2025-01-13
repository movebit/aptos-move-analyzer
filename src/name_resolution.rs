use crate::ext::{from_ast_loc, LocExt};
use crate::name_resolution::Reference::TypeRef;
use move_command_line_common::files::FileHash;
use move_compiler::diagnostics::Diagnostics;
use move_compiler::parser::ast::{
    Definition, LeadingNameAccess, LeadingNameAccess_, ModuleIdent, ModuleMember, StructLayout, Use,
};
use move_compiler::shared::{CompilationEnv, Identifier};
use move_compiler::{parser, Flags, MatchedFileCommentMap};
use move_model::ast::Address;
use move_model::model::{FunId, GlobalEnv};
use std::collections::BTreeSet;

fn parse_file_contents(
    file_contents: &str,
) -> Result<(Vec<Definition>, MatchedFileCommentMap), Diagnostics> {
    let mut env = CompilationEnv::new(Flags::empty(), BTreeSet::new());
    parser::syntax::parse_file_string(&mut env, FileHash::new(file_contents), file_contents)
}

#[derive(Debug)]
pub enum TypeOwner {
    Const {
        module_name: move_model::ast::ModuleName,
        const_name: String,
    },
    Field {
        module_name: move_model::ast::ModuleName,
        struct_: parser::ast::StructDefinition,
        field_name: String,
    },
    VariantField {
        struct_: parser::ast::StructDefinition,
        variant: parser::ast::StructVariant,
        field_name: String,
    },
    FnParameter {
        module_name: move_model::ast::ModuleName,
        fun_id: move_model::model::FunId,
        param_name: String,
    },
    FnReturnType {
        module_name: move_model::ast::ModuleName,
        fun_id: move_model::model::FunId,
    },
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
    ModuleRef {
        address: Option<LeadingNameAccess>,
        module_name: parser::ast::ModuleName,
    },
    TypeRef {
        owner: TypeOwner,
        type_: parser::ast::Type,
    },
}

pub fn find_reference(
    env: &GlobalEnv,
    file_id: codespan::FileId,
    pos: (u32, u32),
) -> Option<Reference> {
    let contains_pos = |loc: move_ir_types::location::Loc| -> bool {
        from_ast_loc(file_id, loc).contains(env, pos)
    };

    let symbol_pool = env.symbol_pool();
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

    let module_name = {
        let address = match module.address {
            Some(leading_name) => match leading_name.value {
                LeadingNameAccess_::AnonymousAddress(numerical_addr) => {
                    Address::Numerical(numerical_addr.into_inner())
                }
                LeadingNameAccess_::Name(address_name) => {
                    Address::Symbolic(symbol_pool.make(&address_name.to_string()))
                }
            },
            None => {
                // todo: do not resolve for modules without address for now
                return None;
            }
        };
        move_model::ast::ModuleName::new(address, symbol_pool.make(&module.name.to_string()))
    };

    if module.is_spec_module {
        // spec 0x1::m {}
        if contains_pos(module.name.loc()) {
            return Some(Reference::ModuleRef {
                address: module.address.clone(),
                module_name: module.name,
            });
        }
    }

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
            ModuleMember::Constant(named_const) => {
                let const_type = &named_const.signature;
                if contains_pos(const_type.loc) {
                    return Some(Reference::TypeRef {
                        owner: TypeOwner::Const {
                            module_name,
                            const_name: named_const.name.to_string(),
                        },
                        type_: const_type.clone(),
                    });
                }
            }
            ModuleMember::Struct(struct_) => {
                let layout = &struct_.layout;
                match layout {
                    StructLayout::Singleton(fields, _) => {
                        for (field, type_) in fields {
                            if contains_pos(type_.loc) {
                                return Some(Reference::TypeRef {
                                    owner: TypeOwner::Field {
                                        module_name,
                                        struct_: struct_.to_owned(),
                                        field_name: field.to_string(),
                                    },
                                    type_: type_.clone(),
                                });
                            }
                        }
                    }
                    StructLayout::Variants(variants) => {
                        for variant in variants {
                            for (field, type_) in &variant.fields {
                                if contains_pos(type_.loc) {
                                    return Some(Reference::TypeRef {
                                        owner: TypeOwner::VariantField {
                                            struct_: struct_.to_owned(),
                                            variant: variant.to_owned(),
                                            field_name: field.to_string(),
                                        },
                                        type_: type_.clone(),
                                    });
                                }
                            }
                        }
                    }
                    StructLayout::Native(_) => {}
                }
            }
            ModuleMember::Function(function) => {
                let function_id = FunId::new(symbol_pool.make(&function.name.to_string()));
                let signature = &function.signature;
                for (parameter, type_) in signature.parameters.clone() {
                    if contains_pos(type_.loc) {
                        return Some(TypeRef {
                            owner: TypeOwner::FnParameter {
                                module_name,
                                fun_id: function_id,
                                param_name: parameter.to_string()
                            },
                            type_
                        })
                    }
                }
                if contains_pos(signature.return_type.loc) {
                    return Some(TypeRef {
                        owner: TypeOwner::FnReturnType {
                            module_name,
                            fun_id: function_id,
                        },
                        type_: signature.return_type.clone(),
                    });
                }
            }
            _ => return None,
        }
    }
    None
}
