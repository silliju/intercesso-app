const express = require('/home/user/webapp/backend/node_modules/express');
const path = require('path');
const fs = require('fs');
const app = express();

const publicDir = path.join(__dirname, 'public');
app.use(express.static(publicDir));

// APK 다운로드 직접 처리
app.get('/intercesso.apk', (req, res) => {
  const apkPath = path.join(publicDir, 'intercesso.apk');
  res.setHeader('Content-Disposition', 'attachment; filename="intercesso.apk"');
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.sendFile(apkPath);
});

// Express v5 호환 - wildcard 없이 처리
app.use((req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

const PORT = 4000;
app.listen(PORT, '0.0.0.0', () => {
  console.log('Intercesso Web App running on port ' + PORT);
});
