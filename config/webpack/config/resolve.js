const path = require('path')

module.exports = {
  resolve: {
    alias: {
      '@bundles': path.resolve(__dirname, '..', '..', '..', 'app/javascript/bundles'),
      '@channels': path.resolve(__dirname, '..', '..', '..', 'app/javascript/channels'),
      '@javascripts': path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts'),
      '@lib':      path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts/lib'),
      '@page':     path.resolve(__dirname, '..', '..', '..', 'app/javascript/javascripts/lib/page'),
      '@stisla':   path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla'),
      'jquery':    path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/jquery'),
      'popper.js': path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/popper.js'),
      'bootstrap': path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/bootstrap'),
      'moment':    path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/moment'),
      'iziToast':  path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/izitoast/dist/js/iziToast'),
      'swal':      path.resolve(__dirname, '..', '..', '..', 'vendor/theme/stisla/node_modules/sweetalert/dist/sweetalert.min'),
    }
  }
}
