// Vercel build step — generate config.js from env vars so the static page
// has its Supabase credentials at deploy time. Local development uses the
// gitignored config.js you create yourself.
const fs = require('fs');

const url = process.env.SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || '';

if (!url || !key) {
  console.warn('build-config: SUPABASE_URL or SUPABASE_ANON_KEY missing — login modal will be disabled');
}

const body = `// Generated at build time from Vercel env vars. Do not edit.
window.HABBIT_CONFIG = {
  SUPABASE_URL: ${JSON.stringify(url)},
  SUPABASE_ANON_KEY: ${JSON.stringify(key)}
};
`;

fs.writeFileSync('config.js', body);
console.log('build-config: wrote config.js (' + body.length + ' bytes)');
