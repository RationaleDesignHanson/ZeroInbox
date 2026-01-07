import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'Zer0 Inbox',
  slug: 'zero-inbox',
  version: '2.0.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'automatic',
  splash: {
    image: './assets/splash.png',
    resizeMode: 'contain',
    backgroundColor: '#0a0a0f',
  },
  assetBundlePatterns: ['**/*'],
  ios: {
    supportsTablet: true,
    bundleIdentifier: 'com.seedny.zeroinbox',
    buildNumber: '1',
    config: {
      usesNonExemptEncryption: false,
    },
    infoPlist: {
      NSFaceIDUsageDescription: 'Use Face ID to authenticate',
      NSCameraUsageDescription: 'Scan documents and QR codes',
      NSPhotoLibraryUsageDescription: 'Attach photos to emails',
      NSMicrophoneUsageDescription: 'Voice commands and dictation',
      UIBackgroundModes: ['audio', 'fetch', 'remote-notification'],
    },
    entitlements: {
      'com.apple.developer.associated-domains': ['applinks:zeroinbox.seedny.com'],
    },
  },
  android: {
    adaptiveIcon: {
      foregroundImage: './assets/adaptive-icon.png',
      backgroundColor: '#0a0a0f',
    },
    package: 'com.seedny.zeroinbox',
    versionCode: 1,
    permissions: [
      'android.permission.CAMERA',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.RECORD_AUDIO',
      'android.permission.VIBRATE',
      'android.permission.RECEIVE_BOOT_COMPLETED',
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
    ],
    googleServicesFile: process.env.GOOGLE_SERVICES_JSON || './google-services.json',
  },
  web: {
    favicon: './assets/favicon.png',
    bundler: 'metro',
  },
  plugins: [
    'expo-router',
    [
      'expo-build-properties',
      {
        ios: {
          deploymentTarget: '15.1',
          newArchEnabled: false,
        },
        android: {
          compileSdkVersion: 34,
          targetSdkVersion: 34,
          buildToolsVersion: '34.0.0',
          newArchEnabled: false,
        },
      },
    ],
    [
      'expo-notifications',
      {
        icon: './assets/notification-icon.png',
        color: '#667eea',
      },
    ],
    'expo-font',
    'expo-secure-store',
    'expo-local-authentication',
  ],
  experiments: {
    typedRoutes: true,
  },
  extra: {
    router: {
      origin: false,
    },
    eas: {
      projectId: '291902f8-04d8-4676-a18b-87fc5d9cf0e4',
    },
    apiBaseUrl: process.env.EXPO_PUBLIC_API_BASE_URL || 'https://api.zeroinbox.seedny.com',
    sentryDsn: process.env.SENTRY_DSN,
    analyticsEnabled: process.env.NODE_ENV === 'production',
  },
  owner: 'rationale',
  runtimeVersion: {
    policy: 'appVersion',
  },
  updates: {
    url: 'https://u.expo.dev/291902f8-04d8-4676-a18b-87fc5d9cf0e4',
    fallbackToCacheTimeout: 0,
  },
  scheme: 'zeroinbox',
});
