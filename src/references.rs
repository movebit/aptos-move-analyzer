// Copyright (c) The BitsLab.MoveBit Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::{
    analyzer_handler::*,
    context::*,
    utils::{path_concat, FileRange},
};
use codespan::{ByteIndex, ByteOffset};
use lsp_server::*;
use lsp_types::*;
use move_command_line_common::files::FileHash;
use move_compiler::parser::lexer::{Lexer, Tok};
// use move_model::{
//     ast::{ExpData::*, Operation::*, SpecBlockTarget},
//     model::{FunId, FunctionEnv, GlobalEnv, ModuleEnv, ModuleId, StructId},
// };
// use codespan::ByteIndex;
// use codespan::ByteOffset;
use itertools::Itertools;
// use move_ir_types::location::*;
use move_model::{
    ast::{ExpData::*, Operation::*, Pattern as MoveModelPattern, SpecBlockTarget},
    model::{FunId, FunctionEnv, GlobalEnv, ModuleEnv, ModuleId, NodeId, StructId},
    symbol::Symbol,
};
use std::{
    collections::{BTreeSet, HashMap},
    path::{Path, PathBuf},
};

/// Handles on_references_request of the language server.
pub fn on_references_request(context: &Context, request: &Request) -> lsp_server::Response {
    log::info!("on_references_request request = {:?}", request);
    let parameters = serde_json::from_value::<ReferenceParams>(request.params.clone())
        .expect("could not deserialize Reference request");
    let fpath = parameters
        .text_document_position
        .text_document
        .uri
        .to_file_path()
        .unwrap();
    let loc = parameters.text_document_position.position;
    let line = loc.line;
    let col = loc.character;
    let fpath = path_concat(std::env::current_dir().unwrap().as_path(), fpath.as_path());

    let mut handler = Handler::new(fpath.clone(), line, col);
    match context.projects.get_project(&fpath) {
        Some(x) => x,
        None => {
            log::error!("project not found:{:?}", fpath.as_path());
            return Response {
                id: "".to_string().into(),
                result: Some(serde_json::json!({"msg": "No available project"})),
                error: None,
            };
        }
    }
    .run_visitor_for_file(&mut handler, &fpath, String::default());
    let locations = handler.convert_to_locations();
    let r = Response::new_ok(
        request.id.clone(),
        serde_json::to_value(GotoDefinitionResponse::Array(locations)).unwrap(),
    );
    let ret_response = r.clone();
    log::info!(
        "------------------------------------\n<on_references_request>ret_response = \n{:?}\n\n",
        ret_response
    );
    context
        .connection
        .sender
        .send(Message::Response(r))
        .unwrap();
    ret_response
}

pub(crate) struct Handler {
    /// The file we are looking for.
    pub(crate) filepath: PathBuf,
    pub(crate) line: u32,
    pub(crate) col: u32,

    pub(crate) mouse_span: codespan::Span,
    pub(crate) capture_items_span: Vec<codespan::Span>,
    pub(crate) result_ref_candidates: Vec<Vec<FileRange>>,
    pub(crate) target_module_id: ModuleId,
    pub(crate) target_function_id: Option<FunId>,
    pub(crate) symbol_2_pattern_id: HashMap<Symbol, NodeId>, // LocalVar => Block::Pattern, only remeber the last pattern
}

impl Handler {
    pub(crate) fn new(filepath: impl Into<PathBuf>, line: u32, col: u32) -> Self {
        Self {
            filepath: filepath.into(),
            line,
            col,
            mouse_span: Default::default(),
            capture_items_span: vec![],
            result_ref_candidates: vec![],
            target_module_id: ModuleId::new(0),
            target_function_id: None,
            symbol_2_pattern_id: HashMap::new(),
        }
    }

    // fn check_move_model_loc_contains_mouse_pos(
    //     &self,
    //     env: &GlobalEnv,
    //     loc: &move_model::model::Loc,
    // ) -> bool {
    //     if let Some(obj_first_col) = env.get_location(&move_model::model::Loc::new(
    //         loc.file_id(),
    //         codespan::Span::new(
    //             loc.span().start(),
    //             loc.span().start() + codespan::ByteOffset(1),
    //         ),
    //     )) {
    //         if let Some(obj_last_col) = env.get_location(&move_model::model::Loc::new(
    //             loc.file_id(),
    //             codespan::Span::new(loc.span().end(), loc.span().end() + codespan::ByteOffset(1)),
    //         )) {
    //             if u32::from(obj_first_col.line) == self.line
    //                 && u32::from(obj_first_col.column) <= self.col
    //                 && self.col <= u32::from(obj_last_col.column)
    //             {
    //                 return true;
    //             }
    //         }
    //     }
    //     false
    // }

    fn convert_loc_to_file_range(
        &mut self,
        env: &GlobalEnv,
        result_loc: &move_model::model::Loc,
    ) -> FileRange {
        let source_str = env.get_source(result_loc).unwrap_or("");
        let (source_file, source_location) = env.get_file_and_location(result_loc).unwrap();

        FileRange {
            path: PathBuf::from(source_file),
            line_start: source_location.line.0,
            col_start: source_location.column.0,
            line_end: source_location.line.0,
            col_end: source_location.column.0 + source_str.len() as u32,
        }
    }

    fn convert_to_locations(&mut self) -> Vec<Location> {
        let mut most_clost_item_idx: usize = 0;
        if let Some(item_idx) = find_smallest_length_index(&self.capture_items_span) {
            most_clost_item_idx = item_idx;
        }

        if !self.result_ref_candidates.is_empty()
            && most_clost_item_idx < self.result_ref_candidates.len()
        {
            let mut ret = Vec::with_capacity(self.result_ref_candidates.len());
            for item in &self.result_ref_candidates[most_clost_item_idx] {
                ret.push(item.mk_location());
            }
            self.capture_items_span.clear();
            self.result_ref_candidates.clear();
            return ret;
        }
        self.capture_items_span.clear();
        self.result_ref_candidates.clear();
        vec![]
    }

    fn get_mouse_loc(&mut self, env: &GlobalEnv, target_fn_or_struct_loc: &move_model::model::Loc) {
        let mut mouse_line_first_col = move_model::model::Loc::new(
            target_fn_or_struct_loc.file_id(),
            codespan::Span::new(
                target_fn_or_struct_loc.span().start() + codespan::ByteOffset(1),
                target_fn_or_struct_loc.span().start() + codespan::ByteOffset(2),
            ),
        );
        let mut mouse_loc = env.get_location(&mouse_line_first_col).unwrap();
        // locate to self.line first column
        while mouse_loc.line.0 < self.line {
            mouse_line_first_col = move_model::model::Loc::new(
                target_fn_or_struct_loc.file_id(),
                codespan::Span::new(
                    mouse_line_first_col.span().start() + codespan::ByteOffset(1),
                    target_fn_or_struct_loc.span().end(),
                ),
            );
            mouse_loc = env.get_location(&mouse_line_first_col).unwrap();
        }
        // locate to self.line last column
        let mut mouse_line_last_col = move_model::model::Loc::new(
            target_fn_or_struct_loc.file_id(),
            codespan::Span::new(
                mouse_line_first_col.span().start() + codespan::ByteOffset(1),
                mouse_line_first_col.span().start() + codespan::ByteOffset(2),
            ),
        );

        mouse_loc = env.get_location(&mouse_line_last_col).unwrap();
        // locate to self.line first column
        while mouse_loc.column.0 < self.col && mouse_loc.line.0 == self.line {
            mouse_line_last_col = move_model::model::Loc::new(
                target_fn_or_struct_loc.file_id(),
                codespan::Span::new(
                    mouse_line_last_col.span().start() + codespan::ByteOffset(1),
                    target_fn_or_struct_loc.span().end(),
                ),
            );
            mouse_loc = env.get_location(&mouse_line_last_col).unwrap();
        }

        let mouse_source = env.get_source(&move_model::model::Loc::new(
            target_fn_or_struct_loc.file_id(),
            codespan::Span::new(
                mouse_line_first_col.span().start(),
                mouse_line_last_col.span().start(),
            ),
        ));
        log::info!("<on_references> -- mouse_source = {:?}", mouse_source);

        self.mouse_span = codespan::Span::new(
            mouse_line_first_col.span().start(),
            mouse_line_last_col.span().start(),
        );
    }

    fn get_which_modules_used_target_module(
        &mut self,
        env: &GlobalEnv,
        target_module: &ModuleEnv,
    ) -> BTreeSet<ModuleId> {
        env.get_modules()
            .filter_map(|module_env| {
                let target_module_name_symbol = target_module.get_name().name();
                let target_module_name_dis = target_module_name_symbol.display(env.symbol_pool());
                let target_module_name_str = target_module_name_dis.to_string();

                if let Ok(module_src) = env.get_source(&module_env.get_loc()) {
                    if module_src.contains(target_module_name_str.as_str()) {
                        return Some(module_env.get_id());
                    }
                }
                None
            })
            .collect()
    }

    fn process_func(&mut self, env: &GlobalEnv) {
        let mut found_target_fun = false;
        let mut target_fun_id = FunId::new(env.symbol_pool().make("name"));
        let target_module = env.get_module(self.target_module_id);
        for fun in target_module.get_functions() {
            let this_fun_loc = fun.get_loc();
            let (_, func_start_pos) = env.get_file_and_location(&this_fun_loc).unwrap();
            let (_, func_end_pos) = env
                .get_file_and_location(&move_model::model::Loc::new(
                    this_fun_loc.file_id(),
                    codespan::Span::new(this_fun_loc.span().end(), this_fun_loc.span().end()),
                ))
                .unwrap();
            if func_start_pos.line.0 <= self.line && self.line < func_end_pos.line.0 {
                target_fun_id = fun.get_id();
                found_target_fun = true;
                break;
            }
        }

        if !found_target_fun {
            log::info!("<on_references> -- not in fun!\n");
            return;
        }

        let target_module = env.get_module(self.target_module_id);
        let target_fun = target_module.get_function(target_fun_id);
        let target_fun_loc = target_fun.get_loc();
        self.get_mouse_loc(env, &target_fun_loc);
        self.process_parameter(env, &target_fun);
        self.process_return_type_and_specifiers(env, &target_fun);

        if let Some(exp) = target_fun.get_def().as_deref() {
            self.process_expr(env, exp);
        };
    }

    fn process_parameter(&mut self, env: &GlobalEnv, target_fun: &FunctionEnv) {
        let fun_paras = target_fun.get_parameters();
        log::info!("process_parameter >> fun_paras: {:?}", fun_paras);
        let mut correct_para_idx = 0;
        let mut whose_end_pos_cloest_mouse = 10000;
        for (para_idx, para) in fun_paras.iter().enumerate() {
            if para.2.span().start() > self.mouse_span.end() {
                break;
            }
            if self.mouse_span.end() - para.2.span().end()
                < codespan::ByteOffset(whose_end_pos_cloest_mouse)
            {
                whose_end_pos_cloest_mouse = (self.mouse_span.end() - para.2.span().end()).into();
                correct_para_idx = para_idx;
            }
        }

        let para = &fun_paras[correct_para_idx];

        let capture_ty_start = para.2.span().end();
        let capture_ty_end = target_fun.get_loc().span().end();
        let capture_ty_loc = move_model::model::Loc::new(
            para.2.file_id(),
            codespan::Span::new(capture_ty_start, capture_ty_end),
        );
        let ty_source = env.get_source(&capture_ty_loc);
        if let Ok(ty_str) = ty_source {
            let mut colon_vec = vec![];
            let mut r_paren_vec = vec![];
            let mut l_brace_vec = vec![];
            let mut lexer = Lexer::new(ty_str, FileHash::new(ty_str));
            let mut capture_ty_end_pos = 0;
            if !lexer.advance().is_err() {
                while lexer.peek() != Tok::EOF {
                    if lexer.peek() == Tok::Colon {
                        if !colon_vec.is_empty() {
                            capture_ty_end_pos = lexer.start_loc();
                            break;
                        }
                        colon_vec.push(lexer.content());
                    }
                    if lexer.peek() == Tok::RParen {
                        r_paren_vec.push(lexer.content());
                    }
                    if lexer.peek() == Tok::LBrace {
                        if !r_paren_vec.is_empty() {
                            capture_ty_end_pos = lexer.start_loc();
                            break;
                        }
                        l_brace_vec.push(lexer.content());
                    }
                    if lexer.advance().is_err() {
                        break;
                    }
                }
            }
            let capture_ty_loc = move_model::model::Loc::new(
                para.2.file_id(),
                codespan::Span::new(
                    capture_ty_start,
                    capture_ty_start + codespan::ByteOffset(capture_ty_end_pos as i64),
                ),
            );
            if capture_ty_loc.span().end() < self.mouse_span.end() {
                return;
            }
            self.process_type(env, &capture_ty_loc, &para.1);
        }
    }

    fn process_return_type_and_specifiers(&mut self, env: &GlobalEnv, target_fun: &FunctionEnv) {
        let ret_ty_vec = target_fun.get_result_type();
        let specifier_vec = target_fun.get_access_specifiers();
        let require_vec = target_fun.get_acquires_global_resources();
        let fn_source = env.get_source(&target_fun.get_loc());
        log::info!("fn_source = {:?}", fn_source);
        if let Ok(fn_str) = fn_source {
            let mut r_paren_vec = vec![];
            let mut l_brace_vec = vec![];
            let mut lexer = Lexer::new(fn_str, FileHash::new(fn_str));
            let mut capture_ty_start_pos = 0;
            let mut capture_ty_end_pos = 0;
            if !lexer.advance().is_err() {
                while lexer.peek() != Tok::EOF {
                    if lexer.peek() == Tok::Colon {
                        if !r_paren_vec.is_empty() {
                            capture_ty_start_pos = lexer.start_loc();
                        }
                    }
                    if lexer.peek() == Tok::RParen {
                        r_paren_vec.push(lexer.content());
                    }
                    if lexer.peek() == Tok::LBrace {
                        if !r_paren_vec.is_empty() {
                            capture_ty_end_pos = lexer.start_loc();
                            break;
                        }
                        l_brace_vec.push(lexer.content());
                    }
                    if lexer.advance().is_err() {
                        break;
                    }
                }
            }
            let capture_ty_loc = move_model::model::Loc::new(
                target_fun.get_loc().file_id(),
                codespan::Span::new(
                    target_fun.get_loc().span().start()
                        + codespan::ByteOffset(capture_ty_start_pos as i64),
                    target_fun.get_loc().span().start()
                        + codespan::ByteOffset(capture_ty_end_pos as i64),
                ),
            );
            if capture_ty_loc.span().start() > self.mouse_span.end()
                || capture_ty_loc.span().end() < self.mouse_span.end()
            {
                log::info!("require_vec = {:?}", require_vec);
                return;
            }
            self.process_type(env, &capture_ty_loc, &ret_ty_vec);

            if let Some(specifiers) = specifier_vec {
                log::info!("specifier = {:?}", specifiers);
                for specifier in specifiers {
                    if specifier.loc.span().start() > self.mouse_span.end()
                        || specifier.loc.span().end() < self.mouse_span.end()
                    {
                        continue;
                    }
                    if let move_model::ast::ResourceSpecifier::Resource(struct_id) =
                        &specifier.resource.1
                    {
                        self.process_type(env, &specifier.resource.0, &struct_id.to_type());
                    }
                }
            }
            if let Some(requires) = require_vec {
                log::info!("requires = {:?}", requires);
                for strct_id in requires {
                    log::info!(
                        "strct_id = {:?}",
                        target_fun
                            .module_env
                            .get_struct(strct_id)
                            .get_full_name_str()
                    );
                    // self.process_type(env, &capture_ty_loc, &move_model::ty::Type::Struct(*mid, *sid, vec![]));
                }
            }
        }
    }

    fn process_spec_func(&mut self, env: &GlobalEnv) {
        let mut found_target_fun = false;
        let mut target_fun_id = FunId::new(env.symbol_pool().make("name"));
        let target_module = env.get_module(self.target_module_id);
        let mut spec_fn_span_loc = target_module.get_loc();

        for spec_block_info in target_module.get_spec_block_infos() {
            if let SpecBlockTarget::Function(_, fun_id) = spec_block_info.target {
                let span_first_col = move_model::model::Loc::new(
                    spec_block_info.loc.file_id(),
                    codespan::Span::new(
                        spec_block_info.loc.span().start(),
                        spec_block_info.loc.span().start() + codespan::ByteOffset(1),
                    ),
                );
                let span_last_col = move_model::model::Loc::new(
                    spec_block_info.loc.file_id(),
                    codespan::Span::new(
                        spec_block_info.loc.span().end(),
                        spec_block_info.loc.span().end() + codespan::ByteOffset(1),
                    ),
                );

                if let Some(s_loc) = env.get_location(&span_first_col) {
                    if let Some(e_loc) = env.get_location(&span_last_col) {
                        if u32::from(s_loc.line) <= self.line && self.line <= u32::from(e_loc.line)
                        {
                            target_fun_id = fun_id;
                            found_target_fun = true;
                            spec_fn_span_loc = spec_block_info.loc.clone();
                            break;
                        }
                    }
                }
            }
        }

        if !found_target_fun {
            log::info!("<on_references> -- not in found_target_spec_fun!\n");
            return;
        }

        let target_fn = target_module.get_function(target_fun_id);
        let target_fn_spec = target_fn.get_spec();
        log::info!("target_fun's spec = {}", env.display(&*target_fn_spec));
        self.get_mouse_loc(env, &spec_fn_span_loc);
        for cond in target_fn_spec.conditions.clone() {
            for exp in cond.all_exps() {
                self.process_expr(env, exp);
            }
        }
    }

    fn process_struct(&mut self, env: &GlobalEnv) {
        let mut found_target_struct = false;
        let mut target_struct_id = StructId::new(env.symbol_pool().make("name"));
        let target_module = env.get_module(self.target_module_id);
        for struct_env in target_module.get_structs() {
            let struct_loc = struct_env.get_loc();
            let (_, struct_start_pos) = env.get_file_and_location(&struct_loc).unwrap();
            let (_, struct_end_pos) = env
                .get_file_and_location(&move_model::model::Loc::new(
                    struct_loc.file_id(),
                    codespan::Span::new(struct_loc.span().end(), struct_loc.span().end()),
                ))
                .unwrap();
            if struct_start_pos.line.0 < self.line && self.line < struct_end_pos.line.0 {
                target_struct_id = struct_env.get_id();
                found_target_struct = true;
                break;
            }
        }

        if !found_target_struct {
            log::info!("<on_references> -- not in struct!\n");
            return;
        }

        let target_module = env.get_module(self.target_module_id);
        let target_struct = target_module.get_struct(target_struct_id);
        let target_struct_loc = target_struct.get_loc();
        self.get_mouse_loc(env, &target_struct_loc);

        for field_env in target_struct.get_fields() {
            let field_name = field_env.get_name();
            let field_name_str = field_name.display(env.symbol_pool());
            log::info!(">> field_name = {}", field_name_str);
            let struct_source = env.get_source(&target_struct_loc);
            if let Ok(struct_str) = struct_source {
                if let Some(index) = struct_str.find(field_name_str.to_string().as_str()) {
                    let field_len = field_name_str.to_string().len();
                    let field_start = target_struct_loc.span().start()
                        + codespan::ByteOffset((index + field_len).try_into().unwrap());
                    // Assuming a relatively large distance
                    let field_end = field_start + codespan::ByteOffset((128).try_into().unwrap());
                    let field_loc = move_model::model::Loc::new(
                        target_struct_loc.file_id(),
                        codespan::Span::new(field_start, field_end),
                    );
                    let field_source = env.get_source(&field_loc);
                    if let Ok(atomic_field_str) = field_source {
                        if let Some(index) = atomic_field_str.find("\n".to_string().as_str()) {
                            let atomic_field_end =
                                field_start + codespan::ByteOffset(index.try_into().unwrap());
                            let atomic_field_loc = move_model::model::Loc::new(
                                target_struct_loc.file_id(),
                                codespan::Span::new(field_start, atomic_field_end),
                            );
                            let atomic_field_source = env.get_source(&atomic_field_loc);
                            // todo: should check mouse_last_col between in scope by atomic_field_loc
                            if atomic_field_loc.span().end() < self.mouse_span.end()
                                || atomic_field_loc.span().start() > self.mouse_span.end()
                            {
                                continue;
                            }
                            log::info!(">> atomic_field_source = {:?}", atomic_field_source);
                            let field_type = field_env.get_type();
                            self.process_type(env, &atomic_field_loc, &field_type);
                        }
                    }
                }
            }
        }
    }

    fn process_spec_struct(&mut self, env: &GlobalEnv) {
        let mut found_target_spec_stct = false;
        let mut target_stct_id = StructId::new(env.symbol_pool().make("name"));
        let target_module = env.get_module(self.target_module_id);
        let mut spec_stct_span_loc = target_module.get_loc();

        for spec_block_info in target_module.get_spec_block_infos() {
            if let SpecBlockTarget::Struct(_, stct_id) = spec_block_info.target {
                let span_first_col = move_model::model::Loc::new(
                    spec_block_info.loc.file_id(),
                    codespan::Span::new(
                        spec_block_info.loc.span().start(),
                        spec_block_info.loc.span().start() + codespan::ByteOffset(1),
                    ),
                );
                let span_last_col = move_model::model::Loc::new(
                    spec_block_info.loc.file_id(),
                    codespan::Span::new(
                        spec_block_info.loc.span().end(),
                        spec_block_info.loc.span().end() + codespan::ByteOffset(1),
                    ),
                );

                if let Some(s_loc) = env.get_location(&span_first_col) {
                    if let Some(e_loc) = env.get_location(&span_last_col) {
                        if u32::from(s_loc.line) <= self.line && self.line <= u32::from(e_loc.line)
                        {
                            target_stct_id = stct_id;
                            found_target_spec_stct = true;
                            spec_stct_span_loc = spec_block_info.loc.clone();
                            break;
                        }
                    }
                }
            }
        }

        if !found_target_spec_stct {
            log::info!("<on_references> -- not in found_target_spec_stct!\n");
            return;
        }

        let target_stct = target_module.get_struct(target_stct_id);
        let target_stct_spec = target_stct.get_spec();
        log::info!("target_stct's spec = {}", env.display(&*target_stct_spec));
        self.get_mouse_loc(env, &spec_stct_span_loc);
        for cond in target_stct_spec.conditions.clone() {
            for exp in cond.all_exps() {
                self.process_expr(env, exp);
            }
        }
    }

    fn process_expr(&mut self, env: &GlobalEnv, exp: &move_model::ast::Exp) {
        log::trace!("process_expr -------------------------\n");
        exp.visit_pre_order(&mut |e| match e {
            Call(_, _, _) => {
                self.process_call(env, e);
                true
            }
            Block(_, pattern, _, _) => {
                self.collect_local_var_in_pattern(pattern);
                self.process_pattern(env, pattern);
                true
            }
            Assign(_, pattern, _) => {
                self.process_pattern(env, pattern);
                self.collect_local_var_in_pattern(pattern);
                true
            }
            _ => {
                log::trace!("________________");
                true
            }
        });
        log::trace!("\nlll << process_expr ^^^^^^^^^^^^^^^^^^^^^^^^^\n");
    }

    fn process_temporary_for_function_para(
        &mut self,
        env: &GlobalEnv,
        source_loc: &move_model::model::Loc,
    ) {
        let source_string = env.get_source(&source_loc).unwrap().to_string();
        if let Some(fun_id) = self.target_function_id {
            let module_env = env.get_module(self.target_module_id);
            let fun_env = module_env.get_function(fun_id);
            for para in fun_env.get_parameters() {
                let para_string = para.0.display(env.symbol_pool()).to_string();
                if para_string != source_string {
                    continue;
                }
                // let para_loc = para.2;
                // self.insert_result(env, &para_loc, &source_loc)
            }
        }
    }

    fn process_call(&mut self, env: &GlobalEnv, expdata: &move_model::ast::ExpData) {
        if let Call(node_id, MoveFunction(mid, fid), _) = expdata {
            let this_call_loc = env.get_node_loc(*node_id);
            if this_call_loc.span().start() < self.mouse_span.end()
                && self.mouse_span.end() < this_call_loc.span().end()
            {
                let called_module = env.get_module(*mid);
                let called_fun = called_module.get_function(*fid);
                log::info!(
                    "<on_references> -- process_call -- get_called_functions = {:?}",
                    called_fun.get_full_name_str()
                );

                if let Some(calling_fns) = called_fun.get_calling_functions() {
                    let mut result_candidates: Vec<FileRange> = Vec::new();
                    for caller in calling_fns {
                        let f = env.get_function(caller);
                        let mut caller_fun_loc = f.get_loc();
                        // need locate called_fun.get_full_name_str() in f's body source
                        let f_source = env.get_source(&caller_fun_loc);
                        if let Ok(f_source_str) = f_source {
                            if let Some(index) =
                                f_source_str.find(called_fun.get_name_str().as_str())
                            {
                                let target_len: usize = called_fun.get_name_str().len();
                                let start = caller_fun_loc.span().start()
                                    + codespan::ByteOffset(index.try_into().unwrap());
                                let end =
                                    start + codespan::ByteOffset((target_len).try_into().unwrap());
                                caller_fun_loc = move_model::model::Loc::new(
                                    caller_fun_loc.file_id(),
                                    codespan::Span::new(start, end),
                                );
                            }
                        }
                        let (caller_fun_file, caller_fun_line) =
                            env.get_file_and_location(&caller_fun_loc).unwrap();

                        let result = FileRange {
                            path: PathBuf::from(caller_fun_file),
                            line_start: caller_fun_line.line.0,
                            col_start: caller_fun_line.column.0,
                            line_end: caller_fun_line.line.0,
                            col_end: caller_fun_line.column.0
                                + called_fun.get_name_str().len() as u32,
                        };
                        result_candidates.push(result);
                    }
                    self.result_ref_candidates.push(result_candidates);
                    self.capture_items_span.push(this_call_loc.span());
                }
            }
        }

        if let Call(node_id, SpecFunction(mid, fid, _), _) = expdata {
            let this_call_loc = env.get_node_loc(*node_id);
            if this_call_loc.span().start() < self.mouse_span.end()
                && self.mouse_span.end() < this_call_loc.span().end()
            {
                let called_module = env.get_module(*mid);
                let spec_fun = called_module.get_spec_fun(*fid);
                log::info!(
                    "<on_references> -- process_call -- get_spec_functions = {}",
                    spec_fun.name.display(env.symbol_pool())
                );
                let mut result_candidates: Vec<FileRange> = Vec::new();
                for callee in spec_fun.callees.clone() {
                    let module = env.get_module(callee.module_id);
                    let decl = module.get_spec_fun(callee.id);

                    let (caller_fun_file, caller_fun_line) =
                        env.get_file_and_location(&decl.loc).unwrap();
                    let result = FileRange {
                        path: PathBuf::from(caller_fun_file),
                        line_start: caller_fun_line.line.0,
                        col_start: caller_fun_line.column.0,
                        line_end: caller_fun_line.line.0,
                        col_end: caller_fun_line.column.0,
                    };
                    result_candidates.push(result);
                }
                self.result_ref_candidates.push(result_candidates);
                self.capture_items_span.push(this_call_loc.span());
            }
        }

        if let Call(node_id, Select(mid, sid, fid), _) = expdata {
            let this_call_loc = env.get_node_loc(*node_id);
            log::trace!(
                ">> exp.visit this_call_loc = {:?}",
                env.get_location(&this_call_loc)
            );
            if this_call_loc.span().start() > self.mouse_span.end()
                || self.mouse_span.end() > this_call_loc.span().end()
            {
                return;
            }
            let mut result_candidates: Vec<FileRange> = Vec::new();
            let called_module = env.get_module(*mid);
            let called_struct = called_module.get_struct(*sid);
            log::trace!(">> called_struct = {:?}", called_struct.get_full_name_str());
            let called_field = called_struct.get_field(*fid);
            let field_name = called_field.get_name();

            result_candidates
                .append(&mut self.find_field_used_of_module(&called_struct.module_env, field_name));
            // for each_mod in env.get_modules() {
            //     result_candidates.append(&mut self.find_field_used_of_module(&each_mod, field_name));
            // }

            let field_name_str = field_name.display(env.symbol_pool());

            let called_struct_loc = called_struct.get_loc();
            let call_struct_source = env.get_source(&called_struct_loc);
            if let Ok(call_struct_str) = call_struct_source {
                if let Some(index) = call_struct_str.find(field_name_str.to_string().as_str()) {
                    let field_start = called_struct_loc.span().start()
                        + codespan::ByteOffset(index.try_into().unwrap());
                    let field_len = field_name_str.to_string().len();
                    let field_end =
                        field_start + codespan::ByteOffset(field_len.try_into().unwrap());
                    let field_loc = move_model::model::Loc::new(
                        called_struct_loc.file_id(),
                        codespan::Span::new(field_start, field_end),
                    );
                    log::info!("field_loc = {:?}", env.get_source(&field_loc));
                    result_candidates.push(self.convert_loc_to_file_range(env, &field_loc));
                }
            }
            self.result_ref_candidates.push(result_candidates);
            self.capture_items_span.push(this_call_loc.span());
        }

        if let Call(node_id, Pack(mid, sid), args) = expdata {
            let this_call_loc = env.get_node_loc(*node_id);
            log::trace!(
                ">> exp.visit this_call_loc = {:?}",
                env.get_location(&this_call_loc)
            );
            if this_call_loc.span().start() > self.mouse_span.end()
                || self.mouse_span.end() > this_call_loc.span().end()
            {
                return;
            }

            if let Ok(pack_struct_str) = env.get_source(&this_call_loc) {
                if let Some(index) = pack_struct_str.find("{") {
                    if usize::from(this_call_loc.span().start()) + index
                        > usize::from(self.mouse_span.end())
                    {
                        let capture_ty_loc = move_model::model::Loc::new(
                            this_call_loc.file_id(),
                            codespan::Span::new(
                                this_call_loc.span().start(),
                                this_call_loc.span().start()
                                    + codespan::ByteOffset(index.try_into().unwrap_or_default()),
                            ),
                        );
                        return self.process_type(
                            env,
                            &capture_ty_loc,
                            &move_model::ty::Type::Struct(*mid, *sid, vec![]),
                        );
                    }
                }
            }

            if let Ok(pack_struct_str) = env.get_source(&this_call_loc) {
                log::info!("pack_struct_str = {:?}", pack_struct_str);
                for arg in args {
                    for node_id in arg.node_ids() {
                        log::info!("arg = {:?}", env.get_source(&env.get_node_loc(node_id)));
                    }
                }

                let re = regex::Regex::new(r"\w+\s*:\s").unwrap();
                let called_module = env.get_module(*mid);
                let called_struct = called_module.get_struct(*sid);

                let mut field_sym: Symbol = called_struct.get_name();
                let mut found_filed = false;
                let _ = re
                    .find_iter(pack_struct_str)
                    .zip(called_struct.get_fields())
                    .map(|(mat, filed_env)| {
                        if !found_filed
                            && this_call_loc.span().start()
                                + codespan::ByteOffset(mat.start().try_into().unwrap_or_default())
                                < self.mouse_span.end()
                            && self.mouse_span.end()
                                < this_call_loc.span().start()
                                    + codespan::ByteOffset(mat.end().try_into().unwrap_or_default())
                        {
                            log::info!(
                                "Match mouse field: {}",
                                &pack_struct_str[mat.start()..mat.end()]
                            );
                            found_filed = true;
                            field_sym = filed_env.get_name();
                        }
                        "xx"
                    })
                    .join("--");

                if found_filed {
                    let result_candidates =
                        self.find_field_used_of_module(&called_module, field_sym);
                    log::info!(
                        "Match pack struct field --> result_candidates = {:?}, field_sym = {:?}",
                        result_candidates,
                        env.symbol_pool().string(field_sym)
                    );
                    self.result_ref_candidates.push(result_candidates);
                    self.capture_items_span.push(this_call_loc.span());
                }
            }
        }
    }

    fn collect_local_var_in_pattern(&mut self, pattern: &MoveModelPattern) {
        for (node_id, sym) in pattern.vars().iter() {
            self.symbol_2_pattern_id.insert(*sym, *node_id);
        }
    }

    fn process_pattern(&mut self, env: &GlobalEnv, pattern: &MoveModelPattern) {
        match pattern {
            MoveModelPattern::Var(node_id, sym) => {
                let this_call_loc = env.get_node_loc(*node_id);
                if this_call_loc.span().start() > self.mouse_span.end()
                    || self.mouse_span.end() > this_call_loc.span().end()
                {
                    return;
                }
                if let Some(sym_pattern_node_id) = self.symbol_2_pattern_id.get(sym) {
                    let pattern_loc = env.get_node_loc(*sym_pattern_node_id);
                    log::info!("Var pattern_loc = {:?}", pattern_loc);
                    // self.insert_result(env, &pattern_loc, &this_call_loc)
                } else {
                    self.process_temporary_for_function_para(env, &this_call_loc);
                }
            }
            MoveModelPattern::Struct(node_id, q_id, pattern_vec) => {
                let this_call_loc = env.get_node_loc(*node_id);
                if this_call_loc.span().start() > self.mouse_span.end()
                    || self.mouse_span.end() > this_call_loc.span().end()
                {
                    return;
                }
                if let Ok(pack_struct_str) = env.get_source(&this_call_loc) {
                    if let Some(index) = pack_struct_str.find("{") {
                        if usize::from(this_call_loc.span().start()) + index
                            > usize::from(self.mouse_span.end())
                        {
                            let capture_ty_loc = move_model::model::Loc::new(
                                this_call_loc.file_id(),
                                codespan::Span::new(
                                    this_call_loc.span().start(),
                                    this_call_loc.span().start()
                                        + codespan::ByteOffset(
                                            index.try_into().unwrap_or_default(),
                                        ),
                                ),
                            );
                            return self.process_type(
                                env,
                                &capture_ty_loc,
                                &move_model::ty::Type::Struct(q_id.module_id, q_id.id, vec![]),
                            );
                        }
                    }
                }
                let pattern_module = env.get_module(q_id.module_id);
                let pattern_struct = pattern_module.get_struct(q_id.id);
                let mut dist_to_pack_start_pos =
                    this_call_loc.span().end() - this_call_loc.span().start();
                let mut field_sym: Symbol = pattern_struct.get_name();
                let mut found_filed = false;
                let _ = pattern_vec
                    .iter()
                    .zip(pattern_struct.get_fields())
                    .map(|(pat, filed_env)| {
                        let field_name = env.symbol_pool().string(filed_env.get_name());
                        if let MoveModelPattern::Var(field_node_id, var_symbol) = pat {
                            let pattern_str = var_symbol.display(env.symbol_pool()).to_string();
                            log::info!(
                                "field_name = {:?}, pattern_str = {:?}",
                                field_name.as_ref(),
                                pattern_str
                            );
                            let field_loc = env.get_node_loc(*field_node_id);
                            if self.mouse_span.end() < field_loc.span().start() {
                                let dist = field_loc.span().start() - self.mouse_span.end();
                                if dist_to_pack_start_pos > dist {
                                    dist_to_pack_start_pos = dist;
                                    field_sym = filed_env.get_name();
                                    found_filed = true;
                                }
                            }
                        }
                        "xx"
                    })
                    .join("--");

                if found_filed {
                    let result_candidates =
                        self.find_field_used_of_module(&pattern_module, field_sym);
                    log::info!(
                        "unpack struct --> result_candidates = {:?}, field_sym = {:?}",
                        result_candidates,
                        env.symbol_pool().string(field_sym)
                    );
                    self.result_ref_candidates.push(result_candidates);
                    self.capture_items_span.push(this_call_loc.span());
                }
            }
            MoveModelPattern::Tuple(node_id, vec_p) => {
                let this_loc = env.get_node_loc(*node_id);
                if this_loc.span().start() > self.mouse_span.end()
                    || self.mouse_span.end() > this_loc.span().end()
                {
                    return;
                }

                for p in vec_p.iter() {
                    self.process_pattern(env, p);
                }
            }
            _ => {}
        }
    }

    fn process_type(
        &mut self,
        env: &GlobalEnv,
        capture_items_loc: &move_model::model::Loc,
        ty: &move_model::ty::Type,
    ) {
        use move_model::ty::Type::*;

        if let Struct(mid, stid, _) = ty {
            let stc_def_module = env.get_module(*mid);
            let type_struct = stc_def_module.get_struct(*stid);
            let mouse_capture_ty_symbol = type_struct.get_name();
            let mouse_capture_ty_symbol_dis = mouse_capture_ty_symbol.display(env.symbol_pool());
            let mouse_capture_ty_symbol_str = mouse_capture_ty_symbol_dis.to_string();

            let mut result_candidates: Vec<FileRange> = Vec::new();
            for reference_module_id in
                self.get_which_modules_used_target_module(env, &stc_def_module)
            {
                let stc_ref_module = env.get_module(reference_module_id);
                for stc_ref_fn in stc_ref_module.get_functions() {
                    let mut stc_ref_fn_loc = stc_ref_fn.get_loc();
                    while let Ok(stc_ref_fn_source) = env.get_source(&stc_ref_fn_loc) {
                        if let Some(index) =
                            stc_ref_fn_source.find(mouse_capture_ty_symbol_str.as_str())
                        {
                            let capture_ref_ty_start = stc_ref_fn_loc.span().start()
                                + codespan::ByteOffset(index.try_into().unwrap());
                            let capture_ref_ty_end = capture_ref_ty_start
                                + codespan::ByteOffset(
                                    (mouse_capture_ty_symbol_str.len()).try_into().unwrap(),
                                );

                            let result_loc = move_model::model::Loc::new(
                                stc_ref_fn_loc.file_id(),
                                codespan::Span::new(capture_ref_ty_start, capture_ref_ty_end),
                            );

                            let (ref_ty_file, ref_ty_pos) =
                                env.get_file_and_location(&result_loc).unwrap();
                            let result = FileRange {
                                path: PathBuf::from(ref_ty_file).clone(),
                                line_start: ref_ty_pos.line.0,
                                col_start: ref_ty_pos.column.0,
                                line_end: ref_ty_pos.line.0,
                                col_end: ref_ty_pos.column.0
                                    + mouse_capture_ty_symbol_str.len() as u32,
                            };
                            result_candidates.push(result);

                            stc_ref_fn_loc = move_model::model::Loc::new(
                                stc_ref_fn_loc.file_id(),
                                codespan::Span::new(
                                    capture_ref_ty_end,
                                    stc_ref_fn_loc.span().end(),
                                ),
                            );
                        } else {
                            break;
                        }
                    }
                }
            }
            self.result_ref_candidates.push(result_candidates);
            self.capture_items_span.push(capture_items_loc.span());
        }
        match ty {
            Vector(type_ptr) => {
                log::trace!(">> type_var is Vector");
                self.process_type(env, capture_items_loc, type_ptr);
            }
            Reference(kind, type_ptr) => {
                log::trace!(">> type_var is Reference {:?}-{:?}", kind, type_ptr);
                self.process_type(env, capture_items_loc, type_ptr);
            }
            _ => {
                log::trace!(">> type_var is default");
            }
        }
    }

    fn run_move_model_visitor_internal(&mut self, env: &GlobalEnv, move_file_path: &Path) {
        let candidate_modules =
            crate::utils::get_modules_by_fpath_in_all_modules(env, &PathBuf::from(move_file_path));
        if candidate_modules.is_empty() {
            log::info!("<on_references>cannot get target module\n");
            return;
        }
        for module_env in candidate_modules.iter() {
            self.target_module_id = module_env.get_id();
            if let Some(s) = move_file_path.to_str() {
                if s.contains(".spec") {
                    self.process_spec_func(env);
                    self.process_spec_struct(env);
                } else {
                    self.process_func(env);
                    self.process_struct(env);
                }
            }
        }
    }
}

impl Handler {
    fn find_field_used_of_module(
        &mut self,
        mod_env: &ModuleEnv,
        field_name: Symbol,
    ) -> Vec<FileRange> {
        let mut result_candidates: Vec<FileRange> = Vec::new();
        result_candidates.append(&mut self.collect_all_select_of_module(mod_env, field_name));
        result_candidates.append(&mut self.collect_all_pack_of_module(mod_env, field_name));
        result_candidates.append(&mut self.collect_all_unpack_of_module(mod_env, field_name));
        result_candidates
    }

    fn collect_all_select_of_module(
        &mut self,
        mod_env: &ModuleEnv,
        field_name: Symbol,
    ) -> Vec<FileRange> {
        let mut result_candidates: Vec<FileRange> = Vec::new();
        for fun in mod_env.get_functions() {
            if let Some(exp) = fun.get_def().as_deref() {
                exp.visit_pre_order(&mut |exp| {
                    match exp {
                        Call(node_id, Select(mid, sid, fid), _) => {
                            let called_module = mod_env.env.get_module(*mid);
                            let called_struct = called_module.get_struct(*sid);
                            let called_field = called_struct.get_field(*fid);
                            if field_name == called_field.get_name() {
                                result_candidates.push(self.convert_loc_to_file_range(
                                    mod_env.env,
                                    &mod_env.env.get_node_loc(*node_id),
                                ));
                            }
                        }
                        _ => {}
                    }
                    true
                });
            }
        }
        result_candidates
    }

    fn collect_all_pack_of_module(
        &mut self,
        mod_env: &ModuleEnv,
        field_name: Symbol,
    ) -> Vec<FileRange> {
        let mut result_candidates: Vec<FileRange> = Vec::new();
        for fun in mod_env.get_functions() {
            if let Some(exp) = fun.get_def().as_deref() {
                exp.visit_pre_order(&mut |exp| {
                    match exp {
                        Call(node_id, Pack(mid, sid), _) => {
                            let mut result_loc = mod_env.env.get_node_loc(*node_id);
                            if let Ok(pack_struct_str) = mod_env.env.get_source(&result_loc) {
                                log::info!("pack_struct_str = {:?}", pack_struct_str);
                                let re = regex::Regex::new(r"\w+\s*:\s").unwrap();
                                let mut min_match_len = codespan::ByteIndex(10000);
                                for mat in re.find_iter(pack_struct_str) {
                                    let field_name_str =
                                        field_name.display(mod_env.env.symbol_pool()).to_string();
                                    if mat.as_str().starts_with(&field_name_str) {
                                        let start_pos = result_loc.span().start()
                                            + ByteOffset(
                                                mat.start().try_into().unwrap_or_default(),
                                            );
                                        let end_pos = start_pos
                                            + ByteOffset(
                                                field_name_str.len().try_into().unwrap_or_default(),
                                            );
                                        if min_match_len
                                            > ByteIndex::default()
                                                + codespan::ByteOffset((end_pos - start_pos).into())
                                        {
                                            min_match_len = ByteIndex::default()
                                                + codespan::ByteOffset(
                                                    (end_pos - start_pos).into(),
                                                );
                                            result_loc = move_model::model::Loc::new(
                                                result_loc.file_id(),
                                                codespan::Span::new(start_pos, end_pos),
                                            );
                                        }
                                    }
                                }
                            }

                            let called_module = mod_env.env.get_module(*mid);
                            let called_struct = called_module.get_struct(*sid);
                            for field in called_struct.get_fields() {
                                if field_name == field.get_name() {
                                    result_candidates.push(
                                        self.convert_loc_to_file_range(mod_env.env, &result_loc),
                                    );
                                    break;
                                }
                            }
                        }
                        _ => {}
                    }
                    true
                });
            }
        }
        result_candidates
    }

    fn collect_all_unpack_of_module(
        &mut self,
        mod_env: &ModuleEnv,
        field_name: Symbol,
    ) -> Vec<FileRange> {
        let mut result_candidates: Vec<FileRange> = Vec::new();
        for fun in mod_env.get_functions() {
            if let Some(exp) = fun.get_def().as_deref() {
                exp.visit_pre_order(&mut |exp| {
                    match exp {
                        Block(_, pattern, _, _) | Assign(_, pattern, _) => {
                            if let MoveModelPattern::Struct(node_id, q_id, _) = pattern {
                                let mut result_loc = mod_env.env.get_node_loc(*node_id);
                                if let Ok(unpack_struct_str) = mod_env.env.get_source(&result_loc) {
                                    log::info!("unpack_struct_str = {:?}", unpack_struct_str);
                                    let re = regex::Regex::new(r"\w+\s*:\s").unwrap();
                                    let mut min_match_len = codespan::ByteIndex(10000);
                                    for mat in re.find_iter(unpack_struct_str) {
                                        let field_name_str = field_name
                                            .display(mod_env.env.symbol_pool())
                                            .to_string();
                                        if mat.as_str().starts_with(&field_name_str) {
                                            let start_pos = result_loc.span().start()
                                                + ByteOffset(
                                                    mat.start().try_into().unwrap_or_default(),
                                                );
                                            let end_pos = start_pos
                                                + ByteOffset(
                                                    field_name_str
                                                        .len()
                                                        .try_into()
                                                        .unwrap_or_default(),
                                                );
                                            if min_match_len
                                                > ByteIndex::default()
                                                    + codespan::ByteOffset(
                                                        (end_pos - start_pos).into(),
                                                    )
                                            {
                                                min_match_len = ByteIndex::default()
                                                    + codespan::ByteOffset(
                                                        (end_pos - start_pos).into(),
                                                    );
                                                result_loc = move_model::model::Loc::new(
                                                    result_loc.file_id(),
                                                    codespan::Span::new(start_pos, end_pos),
                                                );
                                            }
                                        }
                                    }
                                }

                                let pattern_module = mod_env.env.get_module(q_id.module_id);
                                let pattern_struct = pattern_module.get_struct(q_id.id);
                                for field in pattern_struct.get_fields() {
                                    if field_name == field.get_name() {
                                        result_candidates.push(
                                            self.convert_loc_to_file_range(
                                                mod_env.env,
                                                &result_loc,
                                            ),
                                        );
                                        break;
                                    }
                                }
                            }
                        }
                        _ => {}
                    }
                    true
                });
            }
        }
        result_candidates
    }
}

impl ItemOrAccessHandler for Handler {
    fn visit_fun_or_spec_body(&self) -> bool {
        true
    }

    fn finished(&self) -> bool {
        false
    }

    fn handle_project_env(
        &mut self,
        _services: &dyn HandleItemService,
        env: &GlobalEnv,
        move_file_path: &Path,
        _: String,
    ) {
        self.run_move_model_visitor_internal(env, move_file_path);
    }
}

impl std::fmt::Display for Handler {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "reference, file:{:?} line:{} col:{}",
            self.filepath, self.line, self.col
        )
    }
}

pub fn find_smallest_length_index(spans: &[codespan::Span]) -> Option<usize> {
    let mut smallest_length = i64::MAX;
    let mut smallest_index = None;

    for (index, span) in spans.iter().enumerate() {
        let length = span.end() - span.start();
        if length.0 < smallest_length {
            smallest_length = length.0;
            smallest_index = Some(index);
        }
    }

    smallest_index
}
