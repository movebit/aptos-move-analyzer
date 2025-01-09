use codespan::FileId;
use move_core_types::account_address::AccountAddress;
use move_model::ast::{Address, ModuleName, UseDecl};
use move_model::model::{GlobalEnv, Loc};
use std::collections::HashMap;
use std::hash::Hash;

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

pub(crate) trait LocOwner {
    fn loc(&self) -> &move_model::model::Loc;

    fn loc_contains(&self, env: &GlobalEnv, pos: (u32, u32)) -> bool {
        let (line, col) = pos;
        match env.get_location_span(self.loc()) {
            (Some(start_loc), Some(end_loc)) => {
                u32::from(start_loc.line) == line
                    && u32::from(start_loc.column) <= col
                    && col <= u32::from(end_loc.column)
            }
            _ => false,
        }
    }
}

impl LocOwner for UseDecl {
    fn loc(&self) -> &Loc {
        &self.loc
    }
}

pub(crate) fn resolve_named_address_in_module_name(
    module_name: ModuleName,
    env: &GlobalEnv,
    named_address_mapping: &HashMap<String, String>,
) -> Option<ModuleName> {
    let module_addr = match module_name.addr().to_owned() {
        Address::Symbolic(addr_sym) => {
            let addr_name = addr_sym.display(env.symbol_pool()).to_string();
            let Some(addr_value) = named_address_mapping.get(&addr_name) else {
                // cannot find named address
                return None;
            };
            Address::Numerical(AccountAddress::from_hex_literal(addr_value).unwrap())
        }
        addr @ _ => addr,
    };
    Some(ModuleName::new(module_addr, module_name.name()))
}
