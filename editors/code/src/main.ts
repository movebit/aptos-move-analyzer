// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

import { Configuration } from './configuration';
import { Context } from './context';
import { Extension } from './extension';
import { log } from './log';
import { Reg } from './reg';
import * as os from 'os';
import * as path from "path";
import * as fs from "fs";
import * as vscode from 'vscode';
import { downloadLsp } from "./download";
import { getLatestVersion, getLspPath, getVersionFromMetaFile } from "./util";

export type LspStatus =
  | "stopped"
  | "starting"
  | "started"
  | "downloading"
  | "error";

let currentStatus: LspStatus = "stopped";
// let extensionStatus: vscode.StatusBarItem;
let analyzerLspPath: string | undefined;

export async function activate(
  extensionContext: Readonly<vscode.ExtensionContext>,
): Promise<void> {
  const extension = new Extension();
  log.info(`${extension.identifier} version ${extension.version}`);

  const configuration = new Configuration();
  log.info(`configuration: ${configuration.toString()}`);

  await maybeDownloadLspServer();
  log.info('after maybeDownloadLspServer');
  if (analyzerLspPath === undefined) {
    return;
  }

  const context = Context.create(extensionContext, configuration);
  // An error here -- for example, if the path to the `aptos-move-analyzer` binary that the user
  // specified in their settings is not valid -- prevents the extension from providing any
  // more utility, so return early.
  if (context instanceof Error) {
    void vscode.window.showErrorMessage(
      `Could not activate aptos-move-analyzer: ${context.message}.`,
    );
    return;
  }
  // extensionStatus = vscode.window.createStatusBarItem(
  //   vscode.StatusBarAlignment.Left,
  //   0,
  // );

  // Configure other language features.
  context.configureLanguage();

  updateStatus("starting");
  context.startClient();
  log.info('after started client');
  updateStatus("started");

  // Regist all the aptos commands.
  Reg.regaptos(context);

  const reload_cfg = function(): any {
    const client = context.getClient();
    if (client !== undefined) {
      const new_configuration = new Configuration();
      log.info(`new_configuration: ${new_configuration.toString()}`);
      void client.sendRequest('move/lsp/client/inlay_hints/config', new_configuration.inlay_hints_config());
      void client.sendRequest('move/lsp/movefmt/config', new_configuration.movefmt_config());
    }
  };
  reload_cfg();
  vscode.workspace.onDidChangeConfiguration(() => {
    log.info('reload_cfg ...  ');
    reload_cfg();
  });
}

function updateStatus(status: LspStatus, extraInfo?: string) {
  currentStatus = status;
  switch (currentStatus) {
    case "starting":
      updateStatusBar(true, false, "LSP Starting");
      break;
    case "downloading":
      updateStatusBar(true, false, `LSP Downloading - ${extraInfo}`);
      break;
    case "error":
      updateStatusBar(false, true, "LSP Startup Error");
      break;
    default:
      updateStatusBar(false, false);
      break;
  }
}

/**
 * Get the current status of the LSP.
 * @returns A string representing the current status of the LSP, one of "stopped", "starting", "started", "downloading", or "error".
 */
export function getLspStatus(): LspStatus {
  return currentStatus;
}

function updateStatusBar(
  workInProgress: boolean,
  errorOccurred: boolean,
  text?: string,
): void {
  log.info('update workInProgress = ' + workInProgress);
  log.info('update errorOccurred = ' + errorOccurred);
  log.info('update status = ' + text);
  return;
  /*
  let statusIcon = "";
  const statusItem = extensionStatus;
  statusItem.show();
  statusItem.tooltip = new vscode.MarkdownString("", true);
  statusItem.tooltip.isTrusted = true;
  if (errorOccurred) {
    statusIcon = "$(testing-error-icon) ";
  } else if (workInProgress) {
    statusIcon = "$(loading~spin) ";
  }
  if (errorOccurred) {
    statusItem.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.errorForeground",
    );
  } else {
    statusItem.backgroundColor = undefined;
  }
  // statusItem.command = "aptos.move.analyzer.openLogs";
  if (text) {
    statusItem.text = `${statusIcon}${text}`;
  } else {
    statusItem.text = `${statusIcon}AptosMoveAnalyzer`;
  }
  // tooltip
  statusItem.tooltip.appendMarkdown("**General**");
  statusItem.tooltip.appendMarkdown("\n\n---\n\n");
  statusItem.tooltip.appendMarkdown(
    `\n\n[Open Extension Logs](command:aptos.move.analyzer.openLogs)`,
  );

  statusItem.tooltip.appendMarkdown("\n\n**LSP**");
  statusItem.tooltip.appendMarkdown("\n\n---\n\n");
  if (getLspStatus() === "started" || getLspStatus() === "error") {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Restart Server](command:aptos.move.analyzer.lsp.restart)`,
    );
  } else if (getLspStatus() === "stopped") {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Start Server](command:aptos.move.analyzer.lsp.start)`,
    );
  }
  if (
    getLspStatus() !== "stopped" &&
    getLspStatus() !== "downloading" &&
    getLspStatus() !== "error"
  ) {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Stop Server](command:aptos.move.analyzer.lsp.stop)`,
    );
  }
  */
}

async function ensureServerDownloaded(): Promise<string | undefined> {
  const installedVersion = getVersionFromMetaFile(
    os.homedir() + "/.cargo/bin/",
  );

  // See if we have the right version
  // - either its the latest
  // - or we have the one that's configured
  let versionToDownload = "";
  const latestVersion = await getLatestVersion();
  log.info('latestVersion = ' + latestVersion);
  if (latestVersion !== installedVersion) {
    versionToDownload = latestVersion;
  } else {
    // Check that the file wasn't unexpectedly removed
    const lspPath = getLspPath(
      os.homedir() + "/.cargo/bin/",
      installedVersion,
    );
    log.info('installedVersion = ' + installedVersion);
    log.info('lspPath = ' + lspPath);
    if (lspPath === undefined) {
      versionToDownload = latestVersion;
    } else {
      return lspPath;
    }
  }
  log.info('versionToDownload = ' + versionToDownload);
  log.info('Install the LSP and update the version metadata file');
  // Install the LSP and update the version metadata file
  updateStatus("downloading", versionToDownload);
  const configuration = new Configuration();
  const newLspPath = await downloadLsp(
    os.homedir() + "/.cargo/bin/",
    versionToDownload,
    configuration.proxyAddr
  );
  if (newLspPath === undefined) {
    updateStatus("error");
  } else {
    log.info('newLspPath 0827 = ' + newLspPath);
    updateStatus("stopped");
  }
  return newLspPath;
}

async function maybeDownloadLspServer(): Promise<void> {
  var dest_server_path = path.join(
    os.homedir() + "/.cargo/bin/",
    `aptos-move-analyzer`,
  );
  if (process.platform === 'win32') {
    dest_server_path = dest_server_path + '.exe';
  }
  const configuration = new Configuration();
  const userConfiguredAnalyzerLspPath = configuration.serverPath;
  log.info('userConfiguredAnalyzerLspPath = ' + userConfiguredAnalyzerLspPath);
  if (
    userConfiguredAnalyzerLspPath !== dest_server_path
  ) {
    log.info('use lsp-server provided by the user');
    fs.copyFileSync(userConfiguredAnalyzerLspPath, dest_server_path);
    analyzerLspPath = dest_server_path;
  } else {
    log.info('before ensureServerDownloaded');
    analyzerLspPath = await ensureServerDownloaded();
    if (analyzerLspPath !== undefined) {
      fs.copyFileSync(analyzerLspPath, dest_server_path);
    }
    analyzerLspPath = dest_server_path;
    log.info('analyzerLspPath = ' + analyzerLspPath);
  }
}
