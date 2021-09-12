const { environment } = require('@rails/webpacker')

environment.config.merge(require('./config/resolve'))

module.exports = environment
