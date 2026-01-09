/**
 * Index redirect
 * Redirects based on onboarding status
 */

import { Redirect } from 'expo-router';
import { useAuth } from '../contexts/AuthContext';

export default function Index() {
  const { hasCompletedOnboarding } = useAuth();
  
  // Redirect to onboarding if not completed, otherwise to feed
  if (!hasCompletedOnboarding) {
    return <Redirect href="/onboarding" />;
  }
  
  return <Redirect href="/feed" />;
}
