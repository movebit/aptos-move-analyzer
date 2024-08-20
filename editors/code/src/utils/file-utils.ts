import * as vscode from "vscode";
import * as path from "path";
import { promises as fs } from "fs";

export enum GameName {
  Jak1 = "jak1",
  Jak2 = "jak2",
  Jak3 = "jak3",
}

export function openFile(filePath: string | undefined) {
  if (filePath === undefined) {
    return;
  }
  vscode.window.showTextDocument(vscode.Uri.file(filePath));
}

export function determineGameFromPath(path: vscode.Uri): GameName | undefined {
  if (path.fsPath.includes("jak1")) {
    return GameName.Jak1;
  } else if (path.fsPath.includes("jak2")) {
    return GameName.Jak2;
  } else if (path.fsPath.includes("jak3")) {
    return GameName.Jak3;
  }
  return undefined;
}

export async function getDirectoriesInDir(dir: string) {
  const dirs = await fs.readdir(dir, { withFileTypes: true });
  return dirs
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);
}

async function* walkForName(dir: string, name: string): any {
  for await (const d of await fs.opendir(dir)) {
    const entry = path.join(dir, d.name);
    if (d.isDirectory()) {
      yield* walkForName(entry, name);
    } else if (d.isFile() && d.name == name) {
      yield entry;
    }
  }
}

export async function findFileInGoalSrc(
  rootFolder: vscode.Uri,
  gameName: string,
  fileName: string,
): Promise<string | undefined> {
  const searchFolder = vscode.Uri.joinPath(
    rootFolder,
    "goal_src",
    gameName,
  ).fsPath;

  if (!fileName.includes(".gc")) {
    fileName = `${fileName}.gc`;
  }

  const paths = [];
  for await (const path of walkForName(searchFolder, fileName)) {
    paths.push(path);
  }
  if (paths.length === 0) {
    return undefined;
  }
  return paths[0];
}

export async function updateFileBeforeDecomp(
  filePath: string,
  content: string,
) {
  const fileContents = await fs.readFile(filePath, "utf-8");
  const fileLines = fileContents.split(/\r?\n/);
  const newLines = [];
  for (const line of fileLines) {
    if (line.toLowerCase().includes(";; decomp begins")) {
      newLines.push(content);
      newLines.push("\n");
    }
    newLines.push(line);
  }
  await fs.writeFile(filePath, newLines.join("\n"));
}
