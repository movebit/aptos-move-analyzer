import { fetchFromUrl } from "./utils/download";
import * as path from "path";
import * as fs from "fs";
import * as process from "process";
import { log } from "./log";

const artifactNameTemplates: any = {
  darwin: "aptos-move-analyzer-mac-x86_64-__VERSION__",
  linux: "aptos-move-analyzer-ubuntu20.04-x86_64-__VERSION__",
  win32: "aptos-move-analyzer-windows-x86_64-__VERSION__",
};

const versionFileName = "lsp-metadata.json";

export function getLspReleaseAssetName(
  version: string,
  platform: string = process.platform,
): string | undefined {
  if (!(platform in artifactNameTemplates)) {
    log.info(`Unsupported platform '${platform}'`);
    return undefined;
  }
  const nameTemplate = artifactNameTemplates[platform];
  if (nameTemplate === undefined) {
    log.info(`Unsupported platform '${platform}'`);
    return undefined;
  }

  return nameTemplate.replace("__VERSION__", version);
}

export async function getLatestVersion(): Promise<string> {
  try {
    const releasesJSON = await fetchFromUrl(
      "https://api.github.com/repos/movebit/aptos-move-analyzer/releases",
    );
    const releases = JSON.parse(releasesJSON);
    return releases[0].tag_name;
  } catch (err) {
    return "";
  }
}

export function getLspPath(
  extensionPath: string,
  version: string,
): string | undefined {
  const lspName = getLspReleaseAssetName(version);
  if (lspName === undefined) {
    log.info('getLspPath = undefined');
    return undefined;
  }
  const filePath = path.join(extensionPath, lspName);
  if (!fs.existsSync(filePath)) {
    return undefined;
  }
  return filePath;
}

export function getVersionFromMetaFile(extensionPath: string): string {
  const filePath = path.join(extensionPath, versionFileName);
  try {
    const meta = JSON.parse(fs.readFileSync(filePath, "utf8"));
    return meta.version;
  } catch (e: any) {
    log.info("Could not read lsp metadata version file." + e.message);
    return "";
  }
}

export function writeLspMetadata(extensionPath: string, version: string): void {
  const filePath = path.join(extensionPath, versionFileName);
  try {
    fs.writeFileSync(
      filePath,
      JSON.stringify({
        version: version,
      }),
    );
  } catch (e: any) {
    log.info("Could not write lsp metadata file." + e.message);
  }
}
