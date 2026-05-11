module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    // zustand/middleware uses `import.meta.env.MODE` which Metro can't parse.
    // Transform it so the bundle works on web/iOS/Android.
    plugins: ['babel-plugin-transform-import-meta'],
  };
};
