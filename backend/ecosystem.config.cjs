module.exports = {
  apps: [
    {
      name: 'intercesso-backend',
      script: './dist/index.js',
      cwd: '/home/user/webapp/backend',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        SUPABASE_URL: 'your_supabase_url',
        SUPABASE_ANON_KEY: 'your_supabase_anon_key',
        SUPABASE_SERVICE_ROLE_KEY: 'your_supabase_service_role_key',
        JWT_SECRET: 'your_jwt_secret'
      },
      watch: false,
      instances: 1,
      exec_mode: 'fork'
    }
  ]
}
