const express = require('/home/user/webapp/backend/node_modules/express');
const path = require('path');
const fs = require('fs');
const http = require('http');
const app = express();

const publicDir = path.join(__dirname, 'public');
const BACKEND_PORT = 3000;
const BACKEND_HOST = 'localhost';

// ─── API 프록시 미들웨어 ─────────────────────────────────────
// /api/* 요청을 로컬 백엔드(3000번)로 프록시
app.use('/api', (req, res) => {
  const targetPath = '/api' + req.url;
  const options = {
    hostname: BACKEND_HOST,
    port: BACKEND_PORT,
    path: targetPath,
    method: req.method,
    headers: {
      ...req.headers,
      host: `${BACKEND_HOST}:${BACKEND_PORT}`,
    },
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    res.status(502).json({ success: false, message: '백엔드 연결 오류' });
  });

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    req.pipe(proxyReq, { end: true });
  } else {
    proxyReq.end();
  }
});

// ─── 정적 파일 ───────────────────────────────────────────────
app.use(express.static(publicDir));

// APK 다운로드 직접 처리
app.get('/intercesso.apk', (req, res) => {
  const apkPath = path.join(publicDir, 'intercesso.apk');
  if (!fs.existsSync(apkPath)) {
    res.status(404).json({ success: false, message: 'APK not found' });
    return;
  }
  res.setHeader('Content-Disposition', 'attachment; filename="intercesso.apk"');
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.sendFile(apkPath);
});

// SPA fallback - 모든 나머지 요청에 index.html 반환
app.use(function(req, res) {
  res.sendFile(path.join(publicDir, 'index.html'));
});

const PORT = 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log('Intercesso Web App running on port ' + PORT);
  console.log('API proxy: /api/* → http://localhost:' + BACKEND_PORT + '/api/*');
});
