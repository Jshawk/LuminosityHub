const basicAuth = require('express-basic-auth');

module.exports = basicAuth({
  users: { 'luminhub': 'luminhub' }, // Change username and password
  challenge: true,
  unauthorizedResponse: 'Unauthorized'
});
