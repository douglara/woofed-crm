const path = require('path')

module.exports = {
  resolve: {
    alias: {
      '@bundles': path.resolve(__dirname, '..', '..', '..', 'app/javascript/bundles'),
      '@channels': path.resolve(__dirname, '..', '..', '..', 'app/javascript/channels'),
      '@javascripts': path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts'),
      '@lib':      path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts/lib'),
      '@page':     path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts/lib/page'),
    }
  }
}
