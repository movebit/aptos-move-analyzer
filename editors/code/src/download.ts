import { getLspReleaseAssetName, writeLspMetadata } from "./util";
import * as path from "path";
import * as fs from "fs";
import { downloadFromUrl_v2 } from "./utils/download";
import { log } from "./log";


async function canAccessYouTube(): Promise<boolean> {
  try {
    const response = await fetch('https://www.youtube.com/@MoveBit');
    if (!response.ok) {
      log.info('Failed to fetch YouTube data:' + response.status);
      return false;
    }

    const data = await response.json();
    log.info('YouTube data fetched successfully:' + data);
    return true;
  } catch (error) {
    log.info('Error accessing YouTube:' + error);
    return false;
  }
}

export async function downloadLsp(
  extensionPath: string,
  version: string,
  proxy: string,
): Promise<string | undefined> {
  const assetName = getLspReleaseAssetName(version);
  if (assetName === undefined) {
    return undefined;
  }
  log.info('assetName = ' + assetName);
  const url = `https://github.com/movebit/aptos-move-analyzer/releases/download/${version}/${assetName}`;
  const savePath = path.join(extensionPath, assetName);
  log.info('savePath = ' + savePath);

  const b_need_proxy = !await canAccessYouTube();
  log.info('b_need_proxy = ' + b_need_proxy);

  try {
    await downloadFromUrl_v2(
      url,
      savePath,
      9000,
      b_need_proxy ?  proxy : undefined,
      3
    );

    log.info('after downloadFromUrl');
    fs.chmodSync(savePath, 0o775);
    writeLspMetadata(extensionPath, version);
  } catch (e: any) {
    log.info("catch Error downloading aptos-move-analyzer " + e);
    // TODO - backup existing and return that path
    return;
  }
  return savePath;
}
