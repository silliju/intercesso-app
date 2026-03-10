const http = require('http');
const fs = require('fs');
const path = require('path');

const APK_PATH = path.join(__dirname, 'intercesso-app-release.apk');
const PORT = 8080;

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/intercesso-app-release.apk') {
    const stat = fs.statSync(APK_PATH);
    res.writeHead(200, {
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Disposition': 'attachment; filename="intercesso-app-release.apk"',
      'Content-Length': stat.size,
    });
    fs.createReadStream(APK_PATH).pipe(res);
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`APK server running on port ${PORT}`);
});
