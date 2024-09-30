// Copyright (c) The BitsLab.MoveBit Contributors
// SPDX-License-Identifier: Apache-2.0

use super::utils::*;
use crate::{analyzer_handler::*, project::Project};
use anyhow::{Ok, Result};
use codespan_reporting::diagnostic::Severity;
use codespan_reporting::term::termcolor::Buffer;
use move_compiler::shared::{NumericalAddress, PackagePaths};
use move_core_types::account_address::*;
use move_model::metadata::CompilerVersion;
use move_model::metadata::LanguageVersion;
use move_model::model::GlobalEnv;
use move_model::PackageInfo;
use move_package::compilation::build_plan::BuildPlan;
use move_package::source_package::{layout::SourcePackageLayout, manifest_parser::*};
use num_bigint::BigUint;
use std::{
    cell::RefCell,
    cmp::Ordering,
    collections::{BTreeMap, BTreeSet, HashMap},
    path::{Path, PathBuf},
    rc::Rc,
};
use tempfile::tempdir;
use walkdir::WalkDir;

// Determines the base of the number literal, depending on the prefix
pub(crate) fn determine_num_text_and_base(s: &str) -> (&str, move_compiler::shared::NumberFormat) {
    for c in s.chars() {
        if c.is_alphabetic() {
            return (s, move_compiler::shared::NumberFormat::Hex);
        }
    }
    (s, move_compiler::shared::NumberFormat::Decimal)
}

// Parse an address from a decimal or hex encoding
pub fn parse_addr_str_to_number(
    s: &str,
) -> Option<(
    [u8; AccountAddress::LENGTH],
    move_compiler::shared::NumberFormat,
)> {
    let (txt, base) = determine_num_text_and_base(s);

    let parsed = match base {
        move_compiler::shared::NumberFormat::Hex => BigUint::parse_bytes(txt[2..].as_bytes(), 16),
        move_compiler::shared::NumberFormat::Decimal => BigUint::parse_bytes(txt.as_bytes(), 10),
    }?;

    let bytes = parsed.to_bytes_be();
    if bytes.len() > AccountAddress::LENGTH {
        return None;
    }
    let mut result = [0u8; AccountAddress::LENGTH];
    result[(AccountAddress::LENGTH - bytes.len())..].clone_from_slice(&bytes);
    Some((result, base))
}

pub fn parse_addr_str(s: &str) -> Option<NumericalAddress> {
    parse_addr_str_to_number(s).map(|(n, format)| NumericalAddress::new(n, format))
}

pub fn parse_named_address_item(s: &str) -> anyhow::Result<(String, NumericalAddress)> {
    let before_after = s.split('=').collect::<Vec<_>>();

    if before_after.len() != 2 {
        anyhow::bail!(
            "Invalid named address assignment. Must be of the form <address_name>=<address>, but \
             found '{}'",
            s
        );
    }
    let name = before_after[0].parse()?;
    if let Some(addr) = parse_addr_str(before_after[1]) {
        Ok((name, addr))
    } else {
        Ok((
            name,
            NumericalAddress::new(
                AccountAddress::from_hex_literal("0x0")
                    .unwrap()
                    .into_bytes(),
                move_compiler::shared::NumberFormat::Hex,
            ),
        ))
    }
}

pub fn parse_addresses_from_options(
    named_addr_strings: Vec<String>,
) -> anyhow::Result<BTreeMap<String, NumericalAddress>> {
    named_addr_strings
        .iter()
        .map(|x| parse_named_address_item(x))
        .collect()
}

impl Project {
    pub(crate) fn mk_multi_project_key(&self) -> im::HashSet<PathBuf> {
        use im::HashSet;
        let mut v = HashSet::default();
        for x in self.manifest_paths.iter() {
            v.insert(x.clone());
        }
        v
    }

    pub fn load_ok(&self) -> bool {
        self.manifest_not_exists.is_empty() && self.manifest_load_failures.is_empty()
    }

    fn get_global_env_by_move_package_v1(
        &mut self,
        report_err: impl FnMut(String) + Clone,
        pkg_path: &Path,
    ) {
        let mut targets_paths: Vec<PathBuf> = Vec::new();
        let mut dependents_paths: Vec<PathBuf> = Vec::new();
        self.load_project(
            &pkg_path,
            report_err,
            true,
            &mut targets_paths,
            &mut dependents_paths,
        )
        .unwrap_or_default();
        log::info!("targets_paths.len() = {:?}", targets_paths.len());
        log::info!("dependents_paths.len() = {:?}", dependents_paths.len());
        let build_config = move_package::BuildConfig {
            test_mode: true,
            install_dir: Some(tempdir().unwrap().path().to_path_buf()),
            skip_fetch_latest_git_deps: true,
            ..Default::default()
        };
        let resolution_graph = build_config
            .resolution_graph_for_package(&pkg_path, &mut Vec::new())
            .unwrap();
        let named_address_mapping: Vec<_> = resolution_graph
            .extract_named_address_mapping()
            .map(|(name, addr)| format!("{}={}", name.as_str(), addr))
            .collect();
        let addrs = parse_addresses_from_options(named_address_mapping.clone()).unwrap_or_default();

        let targets = vec![PackagePaths {
            name: None,
            paths: targets_paths
                .clone()
                .into_iter()
                .map(|p| p.to_string_lossy().to_string())
                .collect::<Vec<_>>(),
            named_address_map: addrs.clone(),
        }];

        let dependents = vec![PackagePaths {
            name: None,
            paths: dependents_paths
                .clone()
                .into_iter()
                .map(|p| p.to_string_lossy().to_string())
                .collect::<Vec<_>>(),
            named_address_map: addrs.clone(),
        }];

        let attributes: BTreeSet<String> = Default::default();
        self.targets = targets.clone();
        self.dependents = dependents.clone();
        {
            let addrs = move_model::parse_addresses_from_options(named_address_mapping.clone())
                .unwrap_or_default();
            self.global_env = move_model::run_model_builder_in_compiler_mode(
                PackageInfo {
                    sources: targets_paths
                        .clone()
                        .into_iter()
                        .map(|p| p.to_string_lossy().to_string())
                        .collect::<Vec<_>>(),
                    address_map: addrs.clone(),
                },
                PackageInfo {
                    sources: vec![],
                    address_map: addrs.clone(),
                },
                vec![PackageInfo {
                    sources: dependents_paths
                        .clone()
                        .into_iter()
                        .map(|p| p.to_string_lossy().to_string())
                        .collect::<Vec<_>>(),
                    address_map: addrs.clone(),
                }],
                true,
                &attributes,
                LanguageVersion::V2_1,
                false,
                false,
                true,
                true,
            )
            .unwrap_or_default();

            // // Store address aliases
            // let map = addrs
            //     .into_iter()
            //     .map(|(s, a)| (env.symbol_pool().make(&s), a.into_inner()))
            //     .collect();
            // env.set_address_alias_map(map);
        }

        log::info!(
            "env.get_module_count() = {:?}",
            &self.global_env.get_module_count()
        );
        let mut error_writer = Buffer::no_color();

        let mut helper = HashMap::new();
        for (addr_name, addr_num) in addrs.iter() {
            helper.insert(addr_name.clone(), addr_num.to_string());
        }

        self.addrname_2_addrnum = helper;
        self.global_env
            .report_diag(&mut error_writer, Severity::Error);
        self.err_diags = String::from_utf8_lossy(&error_writer.into_inner()).to_string();
        if self.err_diags.len() > 0 {
            log::error!("global_env's err_diags = \n{}", self.err_diags);
        }
    }

    fn get_global_env_by_move_package_v2(&mut self, pkg_path: &Path) -> Result<GlobalEnv> {
        let build_config = move_package::BuildConfig {
            test_mode: true,
            install_dir: Some(tempdir().unwrap().path().to_path_buf()),
            skip_fetch_latest_git_deps: true,
            compiler_config: move_package::CompilerConfig {
                compiler_version: Some(CompilerVersion::V2_1),
                language_version: Some(LanguageVersion::V2_1),
                ..Default::default()
            },
            ..Default::default()
        };
        let resolution_graph =
            build_config.resolution_graph_for_package(pkg_path, &mut Vec::new())?;
        let build_plan = BuildPlan::create(resolution_graph)?;
        let compile_cfg = move_package::CompilerConfig {
            compiler_version: Some(CompilerVersion::V2_1),
            language_version: Some(LanguageVersion::V2_1),
            ..Default::default()
        };
        let (_, env) = build_plan.compile_with_driver(
            &mut std::io::sink(),
            &compile_cfg,
            |_compiler| Ok(Default::default()),
            |compile_option| {
                let addrs = move_model::parse_addresses_from_options(
                    compile_option.named_address_mapping.clone(),
                )?;
                // log::info!("\n*******************************************\n\n addrs = \n{:?}", addrs);
                // log::info!("\n*******************************************\n\n sources = \n{:?}", compile_option.sources);
                // log::info!(
                //     "\n*******************************************\n\n sources = \n{:?}",
                //     compile_option.sources_deps
                // );
                let mut src_dep_paths = vec![];
                let mut dep_paths = vec![];
                for dep_path in &compile_option.sources_deps {
                    if dep_path.split('/').find(|&x| x == "tests").is_some() {
                        continue;
                    }
                    if dep_path.split('\\').find(|&x| x == "tests").is_some() {
                        continue;
                    }
                    if dep_path.contains("/tests/")
                        || dep_path.contains("/tests\\")
                        || dep_path.contains(r"/tests\\")
                        || dep_path.contains(r"\\tests\\")
                    {
                        continue;
                    }
                    src_dep_paths.push(dep_path.clone());
                }
                for dep_path in &compile_option.dependencies {
                    if dep_path.split('/').find(|&x| x == "tests").is_some() {
                        continue;
                    }
                    if dep_path.split('\\').find(|&x| x == "tests").is_some() {
                        continue;
                    }
                    if dep_path.contains("/tests/")
                        || dep_path.contains("/tests\\")
                        || dep_path.contains(r"/tests\\")
                        || dep_path.contains(r"\\tests\\")
                    {
                        continue;
                    }
                    dep_paths.push(dep_path.clone());
                }
                let mut helper = HashMap::new();
                for (addr_name, addr_num) in addrs.iter() {
                    helper.insert(addr_name.clone(), addr_num.to_string());
                }
                self.addrname_2_addrnum = helper;
                let env = move_model::run_model_builder_in_compiler_mode(
                    PackageInfo {
                        sources: compile_option.sources,
                        address_map: addrs.clone(),
                    },
                    PackageInfo {
                        sources: src_dep_paths,
                        address_map: addrs.clone(),
                    },
                    vec![PackageInfo {
                        sources: dep_paths,
                        address_map: addrs.clone(),
                    }],
                    true,
                    &Default::default(),
                    LanguageVersion::V2_1,
                    false,
                    false,
                    true,
                    true,
                )?;
                self.global_env = env;
                log::info!(
                    "self.global_env.get_module_count() = {:?}",
                    self.global_env.get_module_count()
                );
                Ok(Default::default())
            },
        )?;
        Ok(env.unwrap_or_default())
    }

    pub fn new(
        root_dir: impl Into<PathBuf>,
        report_err: impl FnMut(String) + Clone,
    ) -> Result<Self> {
        let working_dir = root_dir.into();
        log::info!("scan modules at {:?}", &working_dir);
        let mut new_project = Self {
            modules: Default::default(),
            manifests: Default::default(),
            hash_file: Rc::new(RefCell::new(PathBufHashMap::new())),
            file_line_mapping: Rc::new(RefCell::new(FileLineMapping::new())),
            manifest_paths: Default::default(),
            manifest_not_exists: Default::default(),
            manifest_load_failures: Default::default(),
            manifest_mod_time: Default::default(),
            global_env: Default::default(),
            current_modifing_file_content: Default::default(),
            targets: vec![],
            dependents: vec![],
            addrname_2_addrnum: Default::default(),
            err_diags: String::default(),
        };
        let mut targets_paths: Vec<PathBuf> = Vec::new();
        let mut dependents_paths: Vec<PathBuf> = Vec::new();
        new_project.load_project(
            &working_dir,
            report_err,
            true,
            &mut targets_paths,
            &mut dependents_paths,
        )?;
        // new_project.get_global_env_by_move_package_v1(report_err, &working_dir);
        new_project.get_global_env_by_move_package_v2(&working_dir)?;
        log::info!(
            "new_project.global_env.get_module_count() = {:?}",
            new_project.global_env.get_module_count()
        );
        let mut error_writer = Buffer::no_color();
        new_project
            .global_env
            .report_diag(&mut error_writer, Severity::Error);
        let err_diags = String::from_utf8_lossy(&error_writer.into_inner()).to_string();
        if err_diags.len() > 0 {
            log::error!(
                "\n*******************************************\n\nerr_diags = \n{}",
                err_diags
            );
            log::error!("\n*******************************************\n");
        }
        Ok(new_project)
    }

    pub fn update_defs(&mut self, file_path: &PathBuf, content: String) {
        use std::result::Result::Ok;
        log::info!("update_defs for file:{:?}", file_path);
        let root_dir = match super::utils::discover_manifest_and_kind(file_path) {
            Some((x, _)) => x,
            None => {
                log::error!("not move project.");
                return;
            }
        };

        let new_project = match Project::new(root_dir.clone(), |msg| log::info!("{}", msg)) {
            Ok(x) => x,
            Err(_) => {
                log::error!("reload project failed");
                return;
            }
        };

        self.current_modifing_file_content = content;
        self.targets = new_project.targets.clone();
        self.dependents = new_project.dependents.clone();
        self.global_env = new_project.global_env;
        log::info!(
            "env.get_module_count() = {:?}",
            &self.global_env.get_module_count()
        );
        let mut error_writer = Buffer::no_color();
        self.global_env
            .report_diag(&mut error_writer, Severity::Error);
        self.err_diags = String::from_utf8_lossy(&error_writer.into_inner()).to_string();
    }

    /// Load a Move.toml project.
    pub(crate) fn load_project(
        &mut self,
        manifest_path: &Path,
        mut report_err: impl FnMut(String) + Clone,
        is_main_source: bool,
        targets_paths: &mut Vec<PathBuf>,
        dependents_paths: &mut Vec<PathBuf>,
    ) -> Result<()> {
        let manifest_path = normal_path(manifest_path);
        if self.modules.get(&manifest_path).is_some() {
            log::trace!("manifest '{:?}' loaded before skipped.", &manifest_path);
            return Ok(());
        }
        if self.manifest_paths.contains(&manifest_path) {
            log::trace!("manifest '{:?}' loaded before skipped.", &manifest_path);
            return Ok(());
        }

        self.manifest_paths.push(manifest_path.clone());
        log::trace!("load manifest file at {:?}", &manifest_path);

        let source_paths1 =
            self.load_layout_files_v2(&manifest_path, SourcePackageLayout::Sources)?;
        let source_paths2 =
            self.load_layout_files_v2(&manifest_path, SourcePackageLayout::Tests)?;
        let source_paths3 =
            self.load_layout_files_v2(&manifest_path, SourcePackageLayout::Scripts)?;
        if is_main_source {
            targets_paths.extend(source_paths1);
            targets_paths.extend(source_paths2);
            targets_paths.extend(source_paths3);
        } else {
            let mut existing_file_names: std::collections::HashSet<_> = dependents_paths
                .iter()
                .filter_map(|path| path.file_name().map(|name| name.to_os_string()))
                .collect();
            for path in source_paths1 {
                if let Some(file_name) = path.file_name().map(|name| name.to_os_string()) {
                    if !existing_file_names.contains(&file_name) {
                        existing_file_names.insert(file_name);
                        dependents_paths.push(path);
                    }
                }
            }
        }

        if !manifest_path.exists() {
            self.manifest_not_exists.insert(manifest_path);
            return anyhow::Result::Ok(());
        }
        {
            let mut file = manifest_path.clone();
            file.push(PROJECT_FILE_NAME);

            self.manifest_mod_time
                .insert(file.clone(), file_modify_time(file.as_path()));
        }

        let manifest = match parse_move_manifest_from_file(&manifest_path) {
            std::result::Result::Ok(x) => x,
            std::result::Result::Err(err) => {
                report_err(format!(
                    "parse manifest '{:?} 'failed.\n addr must exactly 32 length or start with '0x' like '0x2'\n{:?}",
                    manifest_path,
                    err
                ));
                log::error!("parse_move_manifest_from_file failed,err:{:?}", err);
                self.manifest_load_failures.insert(manifest_path.clone());
                return anyhow::Result::Ok(());
            }
        };
        self.manifests.push(manifest.clone());
        // load depends.
        for (dep_name, de) in manifest
            .dependencies
            .iter()
            .chain(manifest.dev_dependencies.iter())
        {
            let de_path = de.local.clone();
            let p = path_concat(manifest_path.as_path(), &de_path);
            log::debug!(
                "load dependency for p '{:?}' manifest_path '{:?}' dep_name '{}'",
                &p,
                &manifest_path,
                dep_name
            );
            self.load_project(
                &p,
                report_err.clone(),
                false,
                targets_paths,
                dependents_paths,
            )?;
        }
        Ok(())
    }

    pub(crate) fn load_layout_files_v2(
        &mut self,
        manifest_path: &Path,
        kind: SourcePackageLayout,
    ) -> Result<Vec<PathBuf>> {
        let mut ret_paths = Vec::new();
        let mut p = manifest_path.to_path_buf();
        p.push(kind.location_str());
        for item in WalkDir::new(&p) {
            let file = match item {
                std::result::Result::Err(_e) => continue,
                std::result::Result::Ok(x) => x,
            };
            if file.file_type().is_file()
                && match file.file_name().to_str() {
                    Some(s) => s.ends_with(".move"),
                    None => continue,
                }
            {
                if file
                    .file_name()
                    .to_str()
                    .map(|x| x.starts_with('.'))
                    .unwrap_or(false)
                {
                    continue;
                }
                log::debug!("load source file {:?}", file.path());
                ret_paths.push(file.path().to_path_buf());
            }
        }
        Ok(ret_paths)
    }

    pub(crate) fn manifest_beed_modified(&self) -> bool {
        self.manifest_mod_time.iter().any(|(k, v)| {
            if file_modify_time(k.as_path()).cmp(v) != Ordering::Equal {
                log::info!(
                    "going to reload project becasue of modify of '{:?}' {:?} {:?}",
                    k.as_path(),
                    file_modify_time(k.as_path()),
                    v
                );
                true
            } else {
                false
            }
        })
    }

    pub fn run_visitor_for_file(
        &self,
        visitor: &mut dyn ItemOrAccessHandler,
        filepath: &Path,
        source_str: String,
    ) {
        visitor.handle_project_env(self, &self.global_env, filepath, source_str);
    }
}
