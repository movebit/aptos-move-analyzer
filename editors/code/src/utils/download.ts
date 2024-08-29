import * as url from "url";
import { https } from "follow-redirects";
import * as fs from "fs";
import { log } from "../log";

export async function fetchFromUrl(fullUrl: string): Promise<string> {
  const q = url.parse(fullUrl);
  return new Promise((resolve, reject) => {
    https
      .get(
        {
          host: q.hostname,
          path: q.pathname,
          port: q.port,
          headers: { "user-agent": "node.js" },
        },
        (res: any) => {
          let data = "";
          res.on("data", (chunk: any) => {
            data += chunk;
          });
          res.on("end", () => {
            resolve(data);
          });
        },
      )
      .on("error", (err: any) => {
        console.error(`Error downloading file from ${url}: ${err.message}`);
        reject(err);
      });
  });
}

import * as https_v2 from "https";
import { HttpsProxyAgent } from "https-proxy-agent";

// export async function downloadFromUrl_v1(
//   url: string,
//   filePath: string,
//   timeout: number = 30000, // default 30s
//   proxy?: string,
//   maxRedirects: number = 5
// ): Promise<void> {
//   // url = "https://filesampleshub.com/download/document/txt/sample2.txt";
//   log.info("Downloading file from " + url);
  
//   return new Promise((resolve, reject) => {
//     const options: https_v2.RequestOptions = {};

//     if (proxy) {
//       const agent = new HttpsProxyAgent(proxy);
//       options.agent = agent;
//       options.rejectUnauthorized = false;
//     }

//     const request = https_v2.get(url, options, (response) => {
//       if (response.statusCode === 200) {
//         const writeStream = fs.createWriteStream(filePath);
//         response
//           .on("end", () => {
//             writeStream.close();
//             log.info("File downloaded to " + filePath);
//             resolve();
//           })
//           .pipe(writeStream);
//       } else if (response.statusCode === 302 && response.headers.location) {
//         // process redirecting
//         if (maxRedirects > 0) {
//           log.info("Redirecting to " + response.headers.location);
//           // Recursively call oneself, follow redirection
//           downloadFromUrl_v2(response.headers.location, filePath, timeout, proxy, maxRedirects - 1)
//             .then(resolve)
//             .catch(reject);
//         } else {
//           reject(new Error("Too many redirects"));
//         }
//       } else {
//         response.resume(); // Consume response to free up memory
//         reject(new Error(`Request failed with status code ${response.statusCode}: ${response.statusMessage}`));
//       }
//     });

//     request.on("error", reject);

//     request.setTimeout(timeout, () => {
//       request.abort();
//       reject(new Error(`Request timed out after ${timeout} ms`));
//     });
//   });
// }

export async function downloadFromUrl_v2(
  url: string,
  filePath: string,
  timeout: number = 30000, // default 30s
  proxy?: string,
  maxRedirects: number = 5
): Promise<void> {
  return new Promise((resolve, reject) => {
    const options: https_v2.RequestOptions = {};

    if (proxy) {
      const agent = new HttpsProxyAgent(proxy);
      options.agent = agent;
      options.rejectUnauthorized = false;
      url = 'https://mirror.ghproxy.com/' + url;
    }
    log.info("Downloading file from " + url);

    const request = https_v2.get(url, options, (response) => {
      if (response.statusCode === 200) {
        const writeStream = fs.createWriteStream(filePath);

        response.pipe(writeStream);

        writeStream.on("finish", () => {
          writeStream.close();
          log.info("File downloaded to " + filePath);
          resolve();
        });

        writeStream.on("error", (err) => {
          fs.unlink(filePath, () => {
            log.info("File write error" + err);
            reject(err);
          });
        });
        
      } else if (response.statusCode === 302 && response.headers.location) {
        // Process redirect
        if (maxRedirects > 0) {
          log.info("Redirecting to " + response.headers.location);
          // Recursively call the function to follow the redirection
          downloadFromUrl_v2(response.headers.location, filePath, timeout, proxy, maxRedirects - 1)
            .then(resolve)
            .catch(reject);
        } else {
          reject(new Error("Too many redirects"));
        }
      } else {
        response.resume(); // Consume response to free up memory
        reject(new Error(`Request failed with status code ${response.statusCode}: ${response.statusMessage}`));
      }
    });

    request.on("error", (err) => {
      reject(err);
    });

    request.setTimeout(timeout, () => {
      request.abort();
      reject(new Error(`Request timed out after ${timeout} ms`));
    });
  });
}
