// UI-only development preview. Never shipped in an extension package.
import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
const root = process.cwd();
const mime = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ttf": "font/ttf",
  ".txt": "text/plain",
};
http
  .createServer(async (req, res) => {
    try {
      const url = new URL(req.url, "http://localhost");
      if (url.pathname === "/preview.js") {
        res.setHeader("Content-Type", "text/javascript");
        res.end(`import {Store} from '/src/store.js';
const listeners=[];
const area={async get(k){const all=JSON.parse(localStorage.getItem('phralio-preview')||'{}');return k===null?all:{[k]:all[k]};},async set(value){const all=await this.get(null);const changes={};for(const [k,v] of Object.entries(value))changes[k]={oldValue:all[k],newValue:v};localStorage.setItem('phralio-preview',JSON.stringify({...all,...value}));for(const f of listeners)f(changes,'local');},async remove(k){const all=await this.get(null);delete all[k];localStorage.setItem('phralio-preview',JSON.stringify(all));}};
const store=new Store(area);
window.chrome={runtime:{async sendMessage(m){try{return {value:await store.handle(m)}}catch(e){return {error:e.message}}}},storage:{onChanged:{addListener:f=>listeners.push(f)}},tabs:{create:async({url})=>window.open(url,'_blank','noopener')}};
const script=document.createElement('script');script.src='/reader.js';document.body.append(script);`);
        return;
      }
      const p = url.pathname === "/" ? "/reader.html" : url.pathname;
      const base =
        p.startsWith("/src/") || p === "/test/fixtures.html"
          ? root
          : path.join(root, "dist/chrome");
      const file = path.resolve(base, "." + decodeURIComponent(p));
      if (!file.startsWith(base + path.sep)) throw Error();
      let content = await readFile(file);
      if (p === "/reader.html")
        content = content
          .toString()
          .replace(
            '<script src="reader.js" defer></script>',
            '<script type="module" src="/preview.js"></script>',
          );
      res.setHeader(
        "Content-Type",
        mime[path.extname(file)] || "application/octet-stream",
      );
      res.end(content);
    } catch {
      res.writeHead(404);
      res.end("Not found");
    }
  })
  .listen(4318, "127.0.0.1", () =>
    console.log(
      "UI preview: http://127.0.0.1:4318 — browser API shim, not an installed extension.",
    ),
  );
