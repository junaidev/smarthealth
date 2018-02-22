// Allows us to use ES6 in our migrations and tests.
require('babel-register')

module.exports = {
  networks: {
    development: {
      host: '192.168.10.55',
      port: 8545,
      network_id: '45634', // Match any network id
      gas: 4712388
    }
  }
}
