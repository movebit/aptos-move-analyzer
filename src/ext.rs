use codespan::FileId;
use line_index::LineCol;
use move_model::model::GlobalEnv;
use move_model::symbol::Symbol;

pub trait GlobalEnvExt {
    fn get_location_at_offset(
        &self,
        file_id: FileId,
        offset: codespan::ByteIndex,
    ) -> Option<codespan::Location>;
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
}

pub(crate) trait LocExt {
    fn contains(&self, env: &GlobalEnv, pos: (u32, u32)) -> bool;
}
impl LocExt for move_model::model::Loc {
    fn contains(&self, env: &GlobalEnv, pos: (u32, u32)) -> bool {
        let (line, col) = pos;

        let file_source = env.get_file_source(self.file_id());
        let file_index = line_index::LineIndex::new(file_source);
        let Some(pos_offset) = file_index.offset(LineCol { line, col }) else {
            return false;
        };
        let pos_index: codespan::ByteIndex = u32::from(pos_offset).into();

        self.span().start() <= pos_index && pos_index <= self.span().end()
    }
}

pub(crate) trait SymbolExt {
    fn to_string(&self, env: &GlobalEnv) -> String;
}
impl SymbolExt for Symbol {
    fn to_string(&self, env: &GlobalEnv) -> String {
        env.symbol_pool().string(*self).to_string()
    }
}
