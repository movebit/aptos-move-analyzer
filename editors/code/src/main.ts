// Copyright (c) The Diem Core Contributors
// Copyright (c) The Move Contributors
// SPDX-License-Identifier: Apache-2.0

import { Configuration } from './configuration';
import { Context } from './context';
import { Extension } from './extension';
import { log } from './log';
import { Reg } from './reg';
import * as vscode from 'vscode';
import { downloadLsp } from "./download";
import { getLatestVersion, getLspPath, getVersionFromMetaFile } from "./util";


let extensionContext: vscode.ExtensionContext;
export async function activate(
  extensionContext: Readonly<vscode.ExtensionContext>,
): Promise<void> {
  extensionContext = extensionContext;
  const extension = new Extension();
  log.info(`${extension.identifier} version ${extension.version}`);

  const configuration = new Configuration();
  log.info(`configuration: ${configuration.toString()}`);

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

  // Configure other language features.
  context.configureLanguage();

  await maybeDownloadLspServer();
  if (analyzerLspPath === undefined) {
    return;
  }

  // All other utilities provided by this extension occur via the language server.
  // await context.startClient();
  context.startClient();
  updateStatus("starting");

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

// import {
//   LanguageClient,
//   LanguageClientOptions,
//   ServerOptions,
//   TransportKind,
// } from "vscode-languageclient/node";

// let activeClient: LanguageClient | undefined;
export type LspStatus =
  | "stopped"
  | "starting"
  | "started"
  | "downloading"
  | "error";

let currentStatus: LspStatus = "stopped";
let extensionStatus: vscode.StatusBarItem;
let analyzerLspPath: string | undefined;

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
  const statusItem = extensionStatus;
  statusItem.show();
  statusItem.tooltip = new vscode.MarkdownString(text, true);
  statusItem.tooltip.isTrusted = true;

  if (workInProgress) {
    statusItem.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.infoForeground",
    );
  } else {
    statusItem.backgroundColor = undefined;
  }

  if (errorOccurred) {
    statusItem.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.errorForeground",
    );
  } else {
    statusItem.backgroundColor = undefined;
  }

  // tooltip
  statusItem.tooltip.appendMarkdown("**General**");
  statusItem.tooltip.appendMarkdown("\n\n---\n\n");
  statusItem.tooltip.appendMarkdown(
    `\n\n[Open Extension Logs](command:analyzer.openLogs)`,
  );

  statusItem.tooltip.appendMarkdown("\n\n**LSP**");
  statusItem.tooltip.appendMarkdown("\n\n---\n\n");
  if (getLspStatus() === "started" || getLspStatus() === "error") {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Restart Server](command:analyzer.lsp.restart)`,
    );
  } else if (getLspStatus() === "stopped") {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Start Server](command:analyzer.lsp.start)`,
    );
  }
  if (
    getLspStatus() !== "stopped" &&
    getLspStatus() !== "downloading" &&
    getLspStatus() !== "error"
  ) {
    statusItem.tooltip.appendMarkdown(
      `\n\n[Stop Server](command:analyzer.lsp.stop)`,
    );
  }

}


import * as path from "path";
import * as fs from "fs";
// import * as process from "process";


async function ensureServerDownloaded(): Promise<string | undefined> {
  const installedVersion = getVersionFromMetaFile(
    extensionContext.extensionPath,
  );
  // const configuredVersion = getConfig().analyzerLspVersion;

  // See if we have the right version
  // - either its the latest
  // - or we have the one that's configured
  let versionToDownload = "";
  {
    const latestVersion = await getLatestVersion();
    if (latestVersion !== installedVersion) {
      versionToDownload = latestVersion;
    } else {
      // Check that the file wasn't unexpectedly removed
      const lspPath = getLspPath(
        extensionContext.extensionPath,
        installedVersion,
      );
      if (lspPath === undefined) {
        versionToDownload = latestVersion;
      } else {
        return lspPath;
      }
    }
  }

  // Install the LSP and update the version metadata file
  updateStatus("downloading", versionToDownload);
  const newLspPath = await downloadLsp(
    extensionContext.extensionPath,
    versionToDownload,
  );
  if (newLspPath === undefined) {
    updateStatus("error");
  } else {
    updateStatus("stopped");
  }
  return newLspPath;
}

async function maybeDownloadLspServer(): Promise<void> {
  const configuration = new Configuration();
  const userConfiguredAnalyzerLspPath = configuration.serverPath;
  if (
    userConfiguredAnalyzerLspPath !== "" &&
    userConfiguredAnalyzerLspPath !== undefined
  ) {
    const userConfiguredAnalyzerLspPath = "";
    // Copy the binary to the extension directory so it doesn't block future compilations
    const lspPath = path.join(
      extensionContext.extensionPath,
      `analyzer-lsp-local.bin`,
    );
    // Check that the LSP is statically linked, we can assume
    // this from the file size (if it's less than 4mb, conservatively it ain't statically linked)
    const stats = fs.statSync(userConfiguredAnalyzerLspPath);
    const fileSizeInBytes = stats.size;
    const fileSizeInMegabytes = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMegabytes <= 4) {
      vscode.window.showErrorMessage(
        "Local LSP path does not appear to point to a statically linked binary",
      );
      return;
    }
    fs.copyFileSync(userConfiguredAnalyzerLspPath, lspPath);
    analyzerLspPath = lspPath;
  } else {
    analyzerLspPath = await ensureServerDownloaded();
  }
}
