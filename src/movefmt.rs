// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::context::*;
// use crate::utils::path_concat;
use lsp_server::*;
use lsp_types::*;

#[allow(unused)]
#[derive(Clone, Copy, serde::Deserialize, Debug)]
pub struct FmtConfig {
    pub enable: bool,
    pub max_width: u8,
    pub indent_size: u8,
}

impl Default for FmtConfig {
    fn default() -> Self {
        Self {
            enable: false,
            max_width: 90,
            indent_size: 4,
        }
    }
}

/// Handles on_movefmt_request of the language server.
pub fn on_movefmt_request(
    context: &Context,
    request: &Request,
    fmt_cfg: &FmtConfig,
) -> lsp_server::Response {
    log::info!(
        "on_movefmt_request request = {:?}, fmt_cfg = {:?}",
        request,
        fmt_cfg
    );
    if !fmt_cfg.enable {
        log::info!("movefmt disenabled.");
        return Response {
            id: "".to_string().into(),
            result: Some(serde_json::json!({"msg": "movefmt disenabled."})),
            error: None,
        };
    }

    let parameters = serde_json::from_value::<DocumentFormattingParams>(request.params.clone())
        .expect("could not deserialize Reference request");
    let fpath = parameters.text_document.uri.to_file_path().unwrap();
    eprintln!("fpath1 = {:?}", fpath);
    // let fpath = path_concat(std::env::current_dir().unwrap().as_path(), fpath.as_path());
    // eprintln!("fpath2 = {:?}", fpath);
    let project = match context.projects.get_project(&fpath) {
        Some(x) => x,
        None => {
            log::error!("project not found:{:?}", fpath.as_path());
            return Response {
                id: "".to_string().into(),
                result: Some(serde_json::json!({"msg": "No available project"})),
                error: None,
            };
        }
    };
    eprintln!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );

    let content_origin = if project.current_modifing_filepath == fpath {
        project.current_modifing_file_content.clone()
    } else {
        std::fs::read_to_string(&fpath).unwrap()
    };
    // let content_origin = std::fs::read_to_string(&fpath).unwrap();
    let mut movefmt_cfg = commentfmt::Config::default();
    movefmt_cfg.set().max_width(fmt_cfg.max_width as usize);
    movefmt_cfg.set().indent_size(fmt_cfg.indent_size as usize);
    let content_format =
        movefmt::core::fmt::format_entry(content_origin.clone(), movefmt_cfg).unwrap();

    eprintln!("content_format = {}", content_format);

    let result_line =
        if content_format.clone().lines().count() >= content_origin.clone().lines().count() {
            content_format.clone().lines().count()
        } else {
            content_origin.clone().lines().count()
        };

    let result = Some(vec![TextEdit {
        range: lsp_types::Range {
            start: Position {
                line: 0,
                character: 0,
            },
            end: Position {
                line: result_line as u32,
                character: 0,
            },
        },
        new_text: content_format.clone(),
    }]);
    let r: Response = Response::new_ok(request.id.clone(), serde_json::to_value(result).unwrap());

    context
        .connection
        .sender
        .send(Message::Response(r.clone()))
        .unwrap();
    r
}
