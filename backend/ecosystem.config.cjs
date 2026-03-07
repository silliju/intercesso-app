module.exports = {
  apps: [
    {
      name: 'intercesso-backend',
      script: './dist/index.js',
      cwd: '/home/user/webapp/backend',
      env_file: '/home/user/webapp/backend/.env',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        SUPABASE_URL: 'https://your-project.supabase.co',
        SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY',
        SUPABASE_SERVICE_ROLE_KEY: 'YOUR_SUPABASE_SERVICE_ROLE_KEY',
        JWT_SECRET: 'YOUR_JWT_SECRET_KEY',
        JWT_EXPIRES_IN: '7d',
        GOOGLE_CLIENT_ID: 'YOUR_GOOGLE_CLIENT_ID',
        KAKAO_REST_API_KEY: 'YOUR_KAKAO_REST_API_KEY'
      },
      watch: false,
      instances: 1,
      exec_mode: 'fork'
    }
  ]
}
