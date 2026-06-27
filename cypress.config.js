import { defineConfig } from 'cypress'
import setupPlugins from './src/test/cypress/plugins/index.js'

export default defineConfig({
  allowCypressEnv: false,
  fileServerFolder: 'src/main/xar-resources',
  fixturesFolder: 'src/test/cypress/fixtures',
  screenshotsFolder: 'src/test/cypress/screenshots',
  videosFolder: 'src/test/cypress/videos',
  downloadsFolder: 'src/test/cypress/downloads',
  e2e: {
    setupNodeEvents (on, config) {
      return setupPlugins(on, config)
    },
    baseUrl: 'http://localhost:8080/exist/apps/fundocs/',
    excludeSpecPattern: 'src/test/cypress/integration/examples/*.js',
    specPattern: 'src/test/cypress/integration/**/*.{js,jsx,ts,tsx}',
    supportFile: 'src/test/cypress/support/index.js'
  }
})
