use codespan::FileId;
use move_model::model::GlobalEnv;

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
            codespan::Span::new(offset, offset + codespan::ByteOffset(1)),
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

pub fn is_loc_span_contains_position(
    env: &GlobalEnv,
    loc: &move_model::model::Loc,
    pos: (u32, u32),
) -> bool {
    let (line, col) = pos;
    match env.get_location_span(loc) {
        (Some(start_loc), Some(end_loc)) => {
            u32::from(start_loc.line) == line
                && u32::from(start_loc.column) <= col
                && col <= u32::from(end_loc.column)
        }
        _ => false,
    }
}

