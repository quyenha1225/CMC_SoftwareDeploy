import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    include: ['tests/unit/**/*.test.{js,jsx}'],
    setupFiles: ['./tests/unit/setup.js'],
    coverage: {
      provider: 'v8', reporter: ['text', 'lcov', 'json-summary'],
      include: ['src/v6/{Auth,Forms,PortalNavigation,StudentTuition}.jsx'],
    },
  },
});
