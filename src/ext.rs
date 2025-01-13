use codespan::{FileId, Span};
use move_compiler::parser::ast::{Definition, LeadingNameAccess_, ModuleIdent, ModuleIdent_};
use move_core_types::account_address::AccountAddress;
use move_model::ast::{Address, ModuleName};
use move_model::model::{GlobalEnv, Loc};
use move_model::symbol::{Symbol, SymbolPool};
use std::collections::HashMap;

pub trait GlobalEnvExt {
    fn get_location_at_offset(
        &self,
        file_id: FileId,
        offset: codespan::ByteIndex,
    ) -> Option<codespan::Location>;

    fn get_location_span(
        &self,
        loc: &move_model::model::Loc,
    ) -> (Option<codespan::Location>, Option<codespan::Location>);
}
impl GlobalEnvExt for GlobalEnv {
    fn get_location_at_offset(
        &self,
        file_id: FileId,
        offset: codespan::ByteIndex,
    ) -> Option<codespan::Location> {
        self.get_location(&move_model::model::Loc::new(
            file_id,
            // `start` can be equal to `end`, get_location() ignores `end` anyway
            codespan::Span::new(offset, offset),
        ))
    }

    fn get_location_span(
        &self,
        loc: &move_model::model::Loc,
    ) -> (Option<codespan::Location>, Option<codespan::Location>) {
        let start_location = self.get_location_at_offset(loc.file_id(), loc.span().start());
        let end_location = self.get_location_at_offset(loc.file_id(), loc.span().end());
        (start_location, end_location)
    }
}

pub(crate) trait LocExt {
    fn contains(&self, env: &GlobalEnv, pos: (u32, u32)) -> bool;
    fn contains_line(&self, env: &GlobalEnv, line: u32) -> bool;
}
impl LocExt for move_model::model::Loc {
    fn contains(&self, env: &GlobalEnv, pos: (u32, u32)) -> bool {
        let (line, col) = pos;
        match env.get_location_span(self) {
            (Some(start_loc), Some(end_loc)) => {
                // todo: rewrite better
                let start_line = u32::from(start_loc.line);
                let end_line = u32::from(end_loc.line);
                if line < start_line || line > end_line {
                    return false;
                }

                if line == start_line && col < u32::from(start_loc.column) { return false; }
                if line == end_line && col > u32::from(end_loc.column) { return false; }

                true
            }
            _ => false,
        }
    }
    fn contains_line(&self, env: &GlobalEnv, line: u32) -> bool {
        match env.get_location_span(self) {
            (Some(start_loc), Some(end_loc)) => {
                u32::from(start_loc.line) <= line && line <= u32::from(end_loc.line)
            }
            _ => false,
        }
    }
}

pub(crate) fn from_ast_loc(
    file_id: FileId,
    ast_loc: move_ir_types::location::Loc,
) -> move_model::model::Loc {
    move_model::model::Loc::new(file_id, Span::new(ast_loc.start(), ast_loc.end()))
}

pub(crate) trait SymbolExt {
    fn string(&self, env: &GlobalEnv) -> String;
}
impl SymbolExt for Symbol {
    fn string(&self, env: &GlobalEnv) -> String {
        env.symbol_pool().string(*self).to_string()
    }
}

pub(crate) fn numeric_fq_module_name(env: &GlobalEnv, module_ident: ModuleIdent) -> Option<String> {
    let ModuleIdent_ { address, module } = module_ident.value;
    let numeric_address = match address.value {
        LeadingNameAccess_::AnonymousAddress(numeric_address) => {
            numeric_address.to_string()
        }
        LeadingNameAccess_::Name(named_address) => {
            let sym = env.symbol_pool().make(named_address.value.as_str());
            let Some(addr) = env.resolve_address_alias(sym) else {
                return None;
            };
            addr.to_standard_string()
        }
    };
    let target_fq_module_name = format!("{}::{}", numeric_address, &module.0.value.as_str().to_string());

    Some(target_fq_module_name)
}

// pub(crate) fn resolve_named_address_in_module_name(
//     module_name: ModuleName,
//     env: &GlobalEnv,
//     named_address_mapping: &HashMap<String, String>,
// ) -> Option<ModuleName> {
//     let module_addr = match module_name.addr().to_owned() {
//         Address::Symbolic(addr_sym) => {
//             let addr_name = addr_sym.display(env.symbol_pool()).to_string();
//             let Some(addr_value) = named_address_mapping.get(&addr_name) else {
//                 // cannot find named address
//                 return None;
//             };
//             Address::Numerical(AccountAddress::from_hex_literal(addr_value).unwrap())
//         }
//         addr @ _ => addr,
//     };
//     Some(ModuleName::new(module_addr, module_name.name()))
// }
