// Copyright (c) The BitsLab.MoveBit Contributors
// SPDX-License-Identifier: Apache-2.0

use aptos_move_analyzer::{
    completion,
    context::{Context, Debounce, FileDiags},
    goto_definition, hover,
    inlay_hints::{self, *},
    move_generate_spec_file::on_generate_spec_file,
    move_generate_spec_sel::on_generate_spec_sel,
    movefmt::*,
    multiproject::MultiProject,
    references, symbols,
    utils::*,
};
use clap::Parser;
use crossbeam::channel::select;
use itertools::Itertools;
use log::{Level, Metadata, Record};
use lsp_server::{Connection, Message, Notification, Request, Response};
use lsp_types::{
    notification::Notification as _, request::Request as _, CompletionOptions,
    HoverProviderCapability, OneOf, SaveOptions, TextDocumentSyncCapability, TextDocumentSyncKind,
    TextDocumentSyncOptions, WorkDoneProgressOptions,
};
use move_command_line_common::files::FileHash;
use std::{collections::HashMap, path::PathBuf, time::Duration};
use url::Url;

struct AnalyzerConfig {
    pub inlay_hints_config: InlayHintsConfig,
    pub movefmt_config: FmtConfig,
}

impl Default for AnalyzerConfig {
    fn default() -> Self {
        Self {
            inlay_hints_config: InlayHintsConfig::default(),
            movefmt_config: FmtConfig::default(),
        }
    }
}

struct SimpleLogger;
impl log::Log for SimpleLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Info
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            eprintln!("{} - {}", record.level(), record.args());
        }
    }

    fn flush(&self) {}
}
const LOGGER: SimpleLogger = SimpleLogger;

pub fn init_log() {
    log::set_logger(&LOGGER)
        .map(|()| log::set_max_level(log::LevelFilter::Trace))
        .unwrap()
}

#[derive(Parser)]
#[clap(author, version, about)]
struct Options {}

fn main() {
    // For now, aptos-move-analyzer only responds to options built-in to clap,
    // such as `--help` or `--version`.
    Options::parse();
    init_log();
    // stdio is used to communicate Language Server Protocol requests and responses.
    // stderr is used for logging (and, when Visual Studio Code is used to communicate with this
    // server, it captures this output in a dedicated "output channel").
    let exe = std::env::current_exe()
        .unwrap()
        .to_string_lossy()
        .to_string();
    log::info!(
        "Starting language server '{}' communicating via stdio...",
        exe
    );

    let (connection, io_threads) = Connection::stdio();
    let mut context = Context {
        projects: MultiProject::new(),
        connection,
        diag_version: FileDiags::new(),
        debounce: Debounce::new(1000),
    };

    let (id, _client_response) = context
        .connection
        .initialize_start()
        .expect("could not start connection initialization");

    let capabilities = serde_json::to_value(lsp_types::ServerCapabilities {
        // The server receives notifications from the client as users open, close,
        // and modify documents.
        text_document_sync: Some(TextDocumentSyncCapability::Options(
            TextDocumentSyncOptions {
                open_close: Some(true),
                change: Some(TextDocumentSyncKind::FULL),
                will_save: None,
                will_save_wait_until: None,
                save: Some(
                    SaveOptions {
                        include_text: Some(true),
                    }
                    .into(),
                ),
            },
        )),
        selection_range_provider: None,
        hover_provider: Some(HoverProviderCapability::Simple(true)),
        completion_provider: Some(CompletionOptions {
            resolve_provider: None,
            trigger_characters: Some(vec![":".to_string(), ".".to_string()]),
            all_commit_characters: None,
            work_done_progress_options: WorkDoneProgressOptions {
                work_done_progress: None,
            },
            completion_item: None,
        }),
        definition_provider: Some(OneOf::Left(true)),
        references_provider: Some(OneOf::Left(true)),
        document_symbol_provider: Some(OneOf::Left(true)),
        ..Default::default()
    })
    .expect("could not serialize server capabilities");

    context
        .connection
        .initialize_finish(
            id,
            serde_json::json!({
                "capabilities": capabilities,
            }),
        )
        .expect("could not finish connection initialization");
    let mut analyzer_cfg = AnalyzerConfig::default();
    loop {
        select! {
            recv(context.connection.receiver) -> message => {
                context.projects.try_reload_projects(&context.connection);
                match message {
                    Ok(Message::Request(request)) => on_request(&mut context, &request , &mut analyzer_cfg),
                    Ok(Message::Response(response)) => on_response(&context, &response),
                    Ok(Message::Notification(notification)) => {
                        match notification.method.as_str() {
                            lsp_types::notification::Exit::METHOD => break,
                            lsp_types::notification::Cancel::METHOD => {
                                // TODO: Currently the server does not implement request cancellation.
                                // It ought to, especially once it begins processing requests that may
                                // take a long time to respond to.
                            }
                            _ => on_notification(&mut context, &notification),
                        }
                    }
                    Err(error) => log::error!("IDE message error: {:?}", error),
                }
            }
        };
    }

    io_threads.join().expect("I/O threads could not finish");
    log::error!("Shut down language server '{}'.", exe);
}

fn on_request(context: &mut Context, request: &Request, analyzer_cfg: &mut AnalyzerConfig) {
    // log::info!("aptos receive method:{}", request.method.as_str());
    match request.method.as_str() {
        lsp_types::request::GotoDefinition::METHOD => {
            goto_definition::on_go_to_def_request(context, request);
        }
        lsp_types::request::References::METHOD => {
            references::on_references_request(context, request);
        }
        lsp_types::request::HoverRequest::METHOD => {
            hover::on_hover_request(context, request);
        }
        lsp_types::request::Completion::METHOD => {
            completion::on_completion_request(context, request);
        }
        lsp_types::request::InlayHintRequest::METHOD => {
            inlay_hints::on_inlay_hints(context, request, &analyzer_cfg.inlay_hints_config);
        }
        lsp_types::request::DocumentSymbolRequest::METHOD => {
            symbols::on_document_symbol_request(context, request);
        }
        lsp_types::request::Formatting::METHOD => {
            on_movefmt_request(context, request, &analyzer_cfg.movefmt_config);
        }
        "move/generate/spec/file" => {
            on_generate_spec_file(context, request, true);
        }
        "move/generate/spec/sel" => {
            on_generate_spec_sel(context, request);
        }
        "move/lsp/client/inlay_hints/config" => {
            let parameters = serde_json::from_value::<InlayHintsConfig>(request.params.clone())
                .expect("could not deserialize inlay hints config");
            log::info!("call inlay_hints config {:?}", parameters);
            if analyzer_cfg.inlay_hints_config.enable == parameters.enable
                && parameters.enable == true
            {
                return;
            }
            analyzer_cfg.inlay_hints_config = parameters;
            if !analyzer_cfg.inlay_hints_config.enable {
                let params = lsp_types::UnregistrationParams {
                    unregisterations: vec![lsp_types::Unregistration {
                        id: lsp_types::request::InlayHintRequest::METHOD.to_string(),
                        method: lsp_types::request::InlayHintRequest::METHOD.to_string(),
                    }],
                };
                context
                    .connection
                    .sender
                    .send(lsp_server::Message::Request(Request {
                        id: "inlay_hints".to_string().into(),
                        method: lsp_types::request::UnregisterCapability::METHOD.to_string(),
                        params: serde_json::json!(params),
                    }))
                    .unwrap();
                eprintln!("--------------------- unregister inlay_hint ---------------------");
                // context
                //     .connection
                //     .sender
                //     .send(lsp_server::Message::Request(Request{
                //         id: "inlay_hints".to_string().into(),
                //         method: lsp_types::request::InlayHintRefreshRequest::METHOD.to_string(),
                //         params: serde_json::json!({}),
                //     })).unwrap();
                // eprintln!("--------------------- refresh inlay_hint ---------------------");
            } else {
                let params = lsp_types::RegistrationParams {
                    registrations: vec![lsp_types::Registration {
                        id: lsp_types::request::InlayHintRequest::METHOD.to_string(),
                        method: lsp_types::request::InlayHintRequest::METHOD.to_string(),
                        register_options: None,
                    }],
                };
                context
                    .connection
                    .sender
                    .send(lsp_server::Message::Request(Request {
                        id: "inlay_hints".to_string().into(),
                        method: lsp_types::request::RegisterCapability::METHOD.to_string(),
                        params: serde_json::json!(params),
                    }))
                    .unwrap();
            }
        }
        "move/lsp/movefmt/config" => {
            let parameters = serde_json::from_value::<FmtConfig>(request.params.clone())
                .expect("could not deserialize movefmt config");
            log::info!("call movefmt config {:?}", parameters);

            if analyzer_cfg.movefmt_config.enable == parameters.enable && parameters.enable == true
            {
                return;
            }

            analyzer_cfg.movefmt_config = parameters;
            if !analyzer_cfg.movefmt_config.enable {
                let params = lsp_types::UnregistrationParams {
                    unregisterations: vec![lsp_types::Unregistration {
                        id: lsp_types::request::Formatting::METHOD.to_string(),
                        method: lsp_types::request::Formatting::METHOD.to_string(),
                    }],
                };
                context
                    .connection
                    .sender
                    .send(lsp_server::Message::Request(Request {
                        id: "movefmt".to_string().into(),
                        method: lsp_types::request::UnregisterCapability::METHOD.to_string(),
                        params: serde_json::json!(params),
                    }))
                    .unwrap();
            } else {
                let params = lsp_types::RegistrationParams {
                    registrations: vec![lsp_types::Registration {
                        id: lsp_types::request::Formatting::METHOD.to_string(),
                        method: lsp_types::request::Formatting::METHOD.to_string(),
                        register_options: None,
                    }],
                };
                context
                    .connection
                    .sender
                    .send(lsp_server::Message::Request(Request {
                        id: "movefmt".to_string().into(),
                        method: lsp_types::request::RegisterCapability::METHOD.to_string(),
                        params: serde_json::json!(params),
                    }))
                    .unwrap();
            }
        }
        _ => {
            log::error!("unsupported request: '{}' from client", request.method)
        }
    }
}

fn on_response(_context: &Context, _response: &Response) {
    log::debug!("handle response[{:?}] from client", _response);
}

fn clear_ui_diag(context: &mut Context, fpath: PathBuf) {
    let proj = match context.projects.get_project(&fpath) {
        Some(x) => x,
        None => {
            log::error!("project not found:{:?}", fpath.as_path());
            return;
        }
    };

    let mut result: HashMap<Url, Vec<lsp_types::Diagnostic>> = HashMap::new();
    let diag_err = proj.err_diags.clone();
    let tokens: Vec<&str> = diag_err.as_str().split("error: ").collect();
    log::info!("clear_ui_diag diag tokens.len = {:?}", tokens.len());
    for token in tokens {
        let line_vec = token.lines().collect_vec();
        if line_vec.len() < 3 {
            continue;
        }
        let err_msg = line_vec[0];
        let loc_str = line_vec[1];
        log::error!("clear_ui_diag diag err_msg = {:?}", err_msg);

        let mut file_path = "";
        let mut pos = lsp_types::Position::default();
        let mut path_start_pos = 0;
        if let Some(start_idx) = loc_str.find('/') {
            path_start_pos = start_idx;
        }
        if let Some(start_idx) = loc_str.find(r":\") {
            // windows path
            path_start_pos = start_idx - 1;
        }
        if let Some(end_idx) = loc_str.find(r".move:") {
            if path_start_pos <= end_idx {
                file_path = &loc_str[path_start_pos..end_idx + ".move".to_string().len()];
                let line = loc_str[end_idx..].split(':').nth(1).unwrap_or_default();
                let col = loc_str[end_idx..].split(':').nth(2).unwrap_or_default();
                let line_num = if line.parse::<u32>().unwrap() > 0 {
                    line.parse::<u32>().unwrap() - 1
                } else {
                    line.parse::<u32>().unwrap()
                };
                let col_num = if col.parse::<u32>().unwrap() > 0 {
                    col.parse::<u32>().unwrap() - 1
                } else {
                    col.parse::<u32>().unwrap()
                };
                pos = lsp_types::Position::new(line_num, col_num);
            }
        }
        log::error!("clear_ui_diag diag file_path = {:?}", file_path);

        if file_path.is_empty() {
            continue;
        }

        let mut code_str = "".to_string();
        for line_idx in 2..line_vec.len() {
            code_str.push_str(line_vec[line_idx]);
            code_str.push_str("\n");
        }
        log::error!(
            "clear_ui_diag diag code_str = {:?}",
            format!("{}\n{}", err_msg, code_str)
        );
        let d = lsp_types::Diagnostic {
            range: lsp_types::Range {
                start: pos,
                end: pos,
            },
            severity: Some(lsp_types::DiagnosticSeverity::ERROR),
            message: format!("{}\n{}", err_msg, code_str),
            ..Default::default()
        };
        let url = url::Url::from_file_path(PathBuf::from(file_path).as_path()).unwrap();
        result.insert(url, vec![d]);
    }
    for (k, _) in result.clone().into_iter() {
        let ds = lsp_types::PublishDiagnosticsParams::new(k.clone(), vec![], None);
        context
            .connection
            .sender
            .send(lsp_server::Message::Notification(Notification {
                method: lsp_types::notification::PublishDiagnostics::METHOD.to_string(),
                params: serde_json::to_value(ds).unwrap(),
            }))
            .unwrap();
    }
}

fn report_diag(context: &mut Context, fpath: PathBuf) {
    let proj = match context.projects.get_project(&fpath) {
        Some(x) => x,
        None => {
            log::error!("project not found:{:?}", fpath.as_path());
            return;
        }
    };

    let mut result: HashMap<Url, Vec<lsp_types::Diagnostic>> = HashMap::new();
    let diag_err = proj.err_diags.clone();
    let tokens: Vec<&str> = diag_err.as_str().split("error: ").collect();
    for token in tokens {
        let line_vec = token.lines().collect_vec();
        if line_vec.len() < 3 {
            continue;
        }
        let err_msg = line_vec[0];
        let loc_str = line_vec[1];

        let mut file_path = "";
        let mut pos = lsp_types::Position::default();
        let mut path_start_pos = 0;
        if let Some(start_idx) = loc_str.find('/') {
            path_start_pos = start_idx;
        }
        if let Some(start_idx) = loc_str.find(r":\") {
            // windows path
            path_start_pos = start_idx - 1;
        }
        if let Some(end_idx) = loc_str.find(r".move:") {
            if path_start_pos <= end_idx {
                file_path = &loc_str[path_start_pos..end_idx + ".move".to_string().len()];
                let line = loc_str[end_idx..].split(':').nth(1).unwrap_or_default();
                let col = loc_str[end_idx..].split(':').nth(2).unwrap_or_default();
                let line_num = if line.parse::<u32>().unwrap() > 0 {
                    line.parse::<u32>().unwrap() - 1
                } else {
                    line.parse::<u32>().unwrap()
                };
                let col_num = if col.parse::<u32>().unwrap() > 0 {
                    col.parse::<u32>().unwrap() - 1
                } else {
                    col.parse::<u32>().unwrap()
                };
                pos = lsp_types::Position::new(line_num, col_num);
            }
        }

        if file_path.contains("aptos-move/")
            || file_path.contains(r"aptos-move\")
            || file_path.is_empty()
        {
            continue;
        }

        let mut code_str = "".to_string();
        for line_idx in 2..line_vec.len() {
            code_str.push_str(line_vec[line_idx]);
            code_str.push_str("\n");
        }

        let d = lsp_types::Diagnostic {
            range: lsp_types::Range {
                start: pos,
                end: pos,
            },
            severity: Some(lsp_types::DiagnosticSeverity::ERROR),
            message: format!("{}\n{}", err_msg, code_str),
            ..Default::default()
        };
        let url = url::Url::from_file_path(PathBuf::from(file_path).as_path()).unwrap();
        result.entry(url)
            .or_insert(Vec::new())
            .push(d);
        
    }
    for (k, v) in result.clone().into_iter() {
        let ds = lsp_types::PublishDiagnosticsParams::new(k.clone(), v, None);
        context
            .connection
            .sender
            .send(lsp_server::Message::Notification(Notification {
                method: lsp_types::notification::PublishDiagnostics::METHOD.to_string(),
                params: serde_json::to_value(ds).unwrap(),
            }))
            .unwrap();
    }
    if result.is_empty() {
        // clear all diags
        context
            .connection
            .sender
            .send(lsp_server::Message::Notification(Notification {
                method: lsp_types::notification::PublishDiagnostics::METHOD.to_string(),
                params: serde_json::to_value(lsp_types::PublishDiagnosticsParams {
                    uri: url::Url::from_file_path(fpath.as_path()).unwrap(),
                    diagnostics: vec![],
                    version: None,
                })
                .unwrap(),
            }))
            .unwrap();
    }
}

fn on_notification(context: &mut Context, notification: &Notification) {
    fn update_defs_on_changed(context: &mut Context, fpath: PathBuf, content: String) {
        let file_hash = FileHash::new(content.as_str());
        context.projects.update_defs(fpath.clone(), content.clone());
        context
            .projects
            .hash_file
            .as_ref()
            .borrow_mut()
            .update(fpath.clone(), file_hash);
        context
            .projects
            .file_line_mapping
            .as_ref()
            .borrow_mut()
            .update(fpath.clone(), content);
        report_diag(context, fpath);
    }

    match notification.method.as_str() {
        lsp_types::notification::DidSaveTextDocument::METHOD => {
            use lsp_types::DidSaveTextDocumentParams;
            let parameters =
                serde_json::from_value::<DidSaveTextDocumentParams>(notification.params.clone())
                    .expect("could not deserialize DidSaveTextDocumentParams request");
            let fpath = parameters.text_document.uri.to_file_path().unwrap();
            let fpath = path_concat(&std::env::current_dir().unwrap(), &fpath);
            let content = std::fs::read_to_string(fpath.as_path());
            let content = match content {
                Ok(x) => x,
                Err(err) => {
                    log::error!("read file failed,err:{:?}", err);
                    return;
                }
            };
            clear_ui_diag(context, fpath.clone());
            update_defs_on_changed(context, fpath.clone(), content.clone());
        }
        lsp_types::notification::DidChangeTextDocument::METHOD => {
            use lsp_types::DidChangeTextDocumentParams;
            let parameters =
                serde_json::from_value::<DidChangeTextDocumentParams>(notification.params.clone())
                    .expect("could not deserialize DidChangeTextDocumentParams request");
            let fpath = parameters.text_document.uri.to_file_path().unwrap();
            let fpath = path_concat(&std::env::current_dir().unwrap(), &fpath);
            clear_ui_diag(context, fpath.clone());
            update_defs_on_changed(
                context,
                fpath.clone(),
                parameters.content_changes.last().unwrap().text.clone(),
            );
        }

        lsp_types::notification::DidOpenTextDocument::METHOD => {
            use lsp_types::DidOpenTextDocumentParams;
            let parameters =
                serde_json::from_value::<DidOpenTextDocumentParams>(notification.params.clone())
                    .expect("could not deserialize DidOpenTextDocumentParams request");
            let fpath = parameters.text_document.uri.to_file_path().unwrap();
            let fpath = path_concat(&std::env::current_dir().unwrap(), &fpath);
            let (mani, _) = match discover_manifest_and_kind(&fpath) {
                Some(x) => x,
                None => {
                    log::error!("not move project.");
                    send_not_project_file_error(context, fpath, true);
                    return;
                }
            };
            match context.projects.get_project(&fpath) {
                Some(_) => {
                    return;
                }
                None => {
                    log::error!("project '{:?}' not found try load.", fpath.as_path());
                }
            };
            let p = match context.projects.load_projects(&context.connection, &mani) {
                anyhow::Result::Ok(x) => x,
                anyhow::Result::Err(e) => {
                    log::error!("load project failed,err:{:?}", e);
                    return;
                }
            };

            context.projects.insert_project(p);
            report_diag(context, fpath);
        }
        lsp_types::notification::DidCloseTextDocument::METHOD => {
            use lsp_types::DidCloseTextDocumentParams;
            let parameters =
                serde_json::from_value::<DidCloseTextDocumentParams>(notification.params.clone())
                    .expect("could not deserialize DidCloseTextDocumentParams request");
            let fpath = parameters.text_document.uri.to_file_path().unwrap();
            let fpath = path_concat(&std::env::current_dir().unwrap(), &fpath);
            let (_, _) = match discover_manifest_and_kind(&fpath) {
                Some(x) => x,
                None => {
                    log::error!("not move project.");
                    send_not_project_file_error(context, fpath, false);
                    return;
                }
            };
        }

        _ => {}
    }
}

fn send_not_project_file_error(context: &mut Context, fpath: PathBuf, is_open: bool) {
    let url = url::Url::from_file_path(fpath.as_path()).unwrap();
    let content = std::fs::read_to_string(fpath.as_path()).unwrap_or_else(|_| "".to_string());
    let lines: Vec<_> = content.lines().collect();
    let last_line = lines.len();
    let last_col = lines.last().map(|x| (*x).len()).unwrap_or(1);
    let ds = lsp_types::PublishDiagnosticsParams::new(
        url,
        if is_open {
            vec![lsp_types::Diagnostic {
                range: lsp_types::Range {
                    start: lsp_types::Position {
                        line: 0,
                        character: 0,
                    },
                    end: lsp_types::Position {
                        line: last_line as u32,
                        character: last_col as u32,
                    },
                },
                message: "This file doesn't belong to a move project.\nMaybe a build artifact???"
                    .to_string(),
                ..Default::default()
            }]
        } else {
            vec![]
        },
        None,
    );
    context
        .connection
        .sender
        .send(lsp_server::Message::Notification(Notification {
            method: lsp_types::notification::PublishDiagnostics::METHOD.to_string(),
            params: serde_json::to_value(ds).unwrap(),
        }))
        .unwrap();
}
