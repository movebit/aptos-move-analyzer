import { getLspReleaseAssetName, writeLspMetadata } from "./util";
import * as path from "path";
import * as fs from "fs";
import { downloadFromUrl } from "./utils/download";
import { log } from "./log";

export async function downloadLsp(
  extensionPath: string,
  version: string,
): Promise<string | undefined> {
  const assetName = getLspReleaseAssetName(version);
  if (assetName === undefined) {
    return undefined;
  }
  log.info('assetName = ' + assetName);
  const url = `https://github.com/movebit/aptos-move-analyzer/releases/download/${version}/${assetName}`;
  const savePath = path.join(extensionPath, assetName);
  log.info('savePath = ' + savePath);
  try {
    await downloadFromUrl(url, savePath);
    log.info('after downloadFromUrl');
    fs.chmodSync(savePath, 0o775);
    // if (path.extname(savePath) === ".bin") {
    //   fs.chmodSync(savePath, 0o775);
    // }
    writeLspMetadata(extensionPath, version);
  } catch (e: any) {
    log.info("catch Error downloading aptos-move-analyzer" + e);
    // TODO - backup existing and return that path
    return;
  }
  return savePath;
}
