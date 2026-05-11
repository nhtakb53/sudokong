const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// zustand's ESM build (.mjs) uses `import.meta.env` which Metro can't parse.
// Disable package.json `exports` so resolution falls back to the CJS `main`
// entrypoint, which is plain ES5.
config.resolver.unstable_enablePackageExports = false;

module.exports = config;
