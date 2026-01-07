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
            '@zero/types': '../../packages/@zero/types/src',
            '@zero/core': '../../packages/@zero/core/src',
            '@zero/api': '../../packages/@zero/api/src',
            '@zero/ui': '../../packages/@zero/ui/src',
          },
        },
      ],
      'react-native-reanimated/plugin',
    ],
  };
};

