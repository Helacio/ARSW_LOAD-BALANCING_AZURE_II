// dns-override.js
// Se activa con:  set NODE_OPTIONS=--require <ruta a este archivo>
// Hace que Node/Newman resuelvan *.azurewebsites.net usando DNS público
// (8.8.8.8 / 1.1.1.1), sin depender del DNS de la red (que no lo resuelve).
const dns = require('dns');

try {
  const resolver = new dns.Resolver();
  resolver.setServers(['8.8.8.8', '1.1.1.1']);

  const origLookup = dns.lookup;

  dns.lookup = function (hostname, options, callback) {
    if (typeof options === 'function') { callback = options; options = {}; }
    if (!options) { options = {}; }

    if (typeof hostname !== 'string' || !/azurewebsites\.net$/i.test(hostname)) {
      return origLookup(hostname, options, callback);
    }

    resolver.resolve4(hostname, function (err, addresses) {
      if (err || !addresses || !addresses.length) {
        return origLookup(hostname, options, callback);
      }
      if (options.all) {
        return callback(null, addresses.map(function (a) { return { address: a, family: 4 }; }));
      }
      callback(null, addresses[0], 4);
    });
  };
} catch (e) {
  // Si algo falla, seguimos con el comportamiento normal.
}
