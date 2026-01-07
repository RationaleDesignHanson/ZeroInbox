/**
 * Index redirect
 * Redirects to the main inbox tab
 */

import { Redirect } from 'expo-router';

export default function Index() {
  return <Redirect href="/(tabs)/inbox" />;
}

