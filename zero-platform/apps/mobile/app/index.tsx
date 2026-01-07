/**
 * Index redirect
 * Redirects to the main feed screen
 */

import { Redirect } from 'expo-router';

export default function Index() {
  return <Redirect href="/feed" />;
}

