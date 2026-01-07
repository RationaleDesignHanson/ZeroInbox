module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      [
        'module-resolver',
        {
          root: ['./'],
          alias: {
            '@zero/types': '../../packages/types/src',
            '@zero/core': '../../packages/core/src',
            '@zero/api': '../../packages/api/src',
            '@zero/ui': '../../packages/ui/src/index.tsx',
          },
        },
      ],
      'react-native-reanimated/plugin',
    ],
  };
};
