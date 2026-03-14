#!/usr/bin/env node
/**
 * railway-env.template.json 또는 railway-env.json 을 채운 뒤 실행하면
 * Railway Variables Raw Editor에 붙여넣을 수 있는 KEY=value 목록을 출력합니다.
 *
 * 사용법:
 *   node docs/railway-env-to-paste.js
 *   node docs/railway-env-to-paste.js docs/railway-env.json
 */

const fs = require('fs');
const path = require('path');

const defaultPath = path.join(__dirname, 'railway-env.json');
const templatePath = path.join(__dirname, 'railway-env.template.json');
const jsonPath = process.argv[2] || (fs.existsSync(defaultPath) ? defaultPath : templatePath);

if (!fs.existsSync(jsonPath)) {
  console.error('JSON 파일이 없습니다. docs/railway-env.template.json 을 docs/railway-env.json 으로 복사한 뒤 값을 채우세요.');
  process.exit(1);
}

let obj;
try {
  obj = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
} catch (e) {
  console.error('JSON 파싱 실패:', e.message);
  process.exit(1);
}

// PORT는 Railway가 자동 주입하므로 제외
const skipKeys = ['PORT', '_comment', '_readme'];
const lines = [];
for (const [key, value] of Object.entries(obj)) {
  if (skipKeys.includes(key) || key.startsWith('_')) continue;
  if (value === undefined || value === null) continue;
  const str = String(value).replace(/\n/g, '\\n');
  lines.push(`${key}=${str}`);
}
console.log(lines.join('\n'));
