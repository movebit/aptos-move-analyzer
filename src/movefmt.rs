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
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );

    // let content_origin = if project.current_modifing_filepath == fpath {
    //     project.current_modifing_file_content.clone()
    // } else {
    //    std::fs::read_to_string(&fpath).unwrap()
    // };
    let content_origin = std::fs::read_to_string(&fpath).unwrap();
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    let mut movefmt_cfg = commentfmt::Config::default();
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    movefmt_cfg.set().max_width(fmt_cfg.max_width as usize);
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    movefmt_cfg.set().indent_size(fmt_cfg.indent_size as usize);
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    let content_format =
        movefmt::core::fmt::format_entry(content_origin.clone(), movefmt_cfg);
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    if content_format.is_err() {
        let r = Response::new_err(request.id.clone(), -1, "format failed".to_string());
        context
            .connection
            .sender
            .send(Message::Response(r.clone()))
            .unwrap();
        return r;
    }
    log::info!(
        "current_modifing_filepath = {:?}",
        project.current_modifing_filepath
    );
    let content_format = content_format.unwrap();
    log::info!("format result: {}", content_format);

    let mut text_edits = vec![];


    let before_line = content_origin.clone().lines().count();
    let after_line = content_format.clone().lines().count();

    text_edits.push(TextEdit {
        range: lsp_types::Range {
            start: Position {
                line: 0,
                character: 0,
            },
            end: Position {
                line: after_line as u32,
                character: 0,
            },
        },
        new_text: content_format.clone(),
    });

    if before_line > after_line {
        text_edits.push(TextEdit {
            range: lsp_types::Range {
                start: Position {
                    line: (after_line + 1) as u32,
                    character: 0,
                },
                end: Position {
                    line: before_line as u32,
                    character: 0,
                },
            },
            new_text: "".to_string(),
        });
    }
   

    let r: Response = Response::new_ok(
        request.id.clone(),
         serde_json::to_value(Some(text_edits)).unwrap()
    );

    context
        .connection
        .sender
        .send(Message::Response(r.clone()))
        .unwrap();
    r
}
