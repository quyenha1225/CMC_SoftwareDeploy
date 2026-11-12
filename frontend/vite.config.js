import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const port = Number(env.DEV_SERVER_PORT || 5173);
  const target = env.SMS_TEST_API_TARGET || env.API_PROXY_TARGET || 'http://127.0.0.1:8081';
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid DEV_SERVER_PORT');
  if (!/^https?:\/\//.test(target)) throw new Error('API_PROXY_TARGET must use http:// or https://');
  return {
    plugins: [react()],
    server: {
      port,
      host: env.DEV_SERVER_HOST || '127.0.0.1',
      proxy: { '/api': target },
    },
  };
});
