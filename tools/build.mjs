// game/ klasöründeki en güncel FootballCareerSimulator_v*.jsx dosyasını React ile
// birlikte tek bir JS'e paketleyip game/NextGent.html olarak yazar.
// Çıktı sunucusuz çalışır: dosyaya çift tıklamak yeterli.
//   npm install && npm run build
import { build } from "esbuild";
import { readdirSync, writeFileSync, mkdtempSync, rmSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const gameDir = join(root, "game");
const ver = (f) => Number((f.match(/_v(\d+)\.jsx$/) || [])[1] || 0);
const latest = readdirSync(gameDir).filter((f) => /^FootballCareerSimulator_v\d+\.jsx$/.test(f)).sort((a, b) => ver(b) - ver(a))[0];
if (!latest) { console.error("game/ içinde FootballCareerSimulator_v*.jsx bulunamadı"); process.exit(1); }

const tmp = mkdtempSync(join(tmpdir(), "nextgent-"));
const entry = join(tmp, "entry.jsx");
writeFileSync(entry, `import { createRoot } from "react-dom/client";
import App from ${JSON.stringify(join(gameDir, latest))};
createRoot(document.getElementById("root")).render(<App/>);
`);
try {
  const out = await build({
    entryPoints: [entry], bundle: true, minify: true, write: false, format: "iife",
    jsx: "automatic", loader: { ".jsx": "jsx" }, target: ["chrome100", "firefox100", "safari15"],
    define: { "process.env.NODE_ENV": '"production"' },
    nodePaths: [join(root, "node_modules")], logLevel: "warning",
  });
  // "</script" dizisi satır içi betiği erken kapatmasın
  const js = out.outputFiles[0].text.replace(/<\/script/gi, "<\\/script");
  const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>NextGent — Futbol Kariyeri</title>
</head>
<body style="margin:0;background:#070c14">
<div id="root"></div>
<script>${js}</script>
</body>
</html>
`;
  writeFileSync(join(gameDir, "NextGent.html"), html);
  console.log(`${latest} → game/NextGent.html (${(html.length / 1024).toFixed(0)} KB)`);
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
