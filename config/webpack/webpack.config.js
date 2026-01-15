const { generateWebpackConfig, merge } = require('shakapacker')
const path = require('path')

const customConfig = {
  resolve: {
    alias: {
      // Aliases existentes do projeto
      '@bundles': path.resolve(__dirname, '../../app/javascript/bundles'),
      '@channels': path.resolve(__dirname, '../../app/javascript/channels'),
      '@javascripts': path.resolve(__dirname, '../../app/javascript/javascripts'),
      '@lib': path.resolve(__dirname, '../../app/javascript/javascripts/lib'),
      '@page': path.resolve(__dirname, '../../app/javascript/javascripts/lib/page'),
      // Alias para compatibilidade com libs que importam de "stimulus"
      'stimulus': '@hotwired/stimulus'
    }
  }
}

module.exports = merge(generateWebpackConfig(), customConfig)
