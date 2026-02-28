module.exports = {
  apps: [{
    name: 'intercesso-webapp',
    script: 'server.js',
    cwd: '/home/user/webapp/web-app',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    env: { NODE_ENV: 'production', PORT: 4000 }
  }]
}
