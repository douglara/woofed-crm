import react from '@vitejs/plugin-react-swc'
import { resolve } from 'path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react({
      devTarget: 'es2022',
    }),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'app/javascript'),
      '~': resolve(__dirname, 'app/javascript'),
    },
  },
  server: {
    hmr: {
      protocol: 'ws',
    },
  },
})
