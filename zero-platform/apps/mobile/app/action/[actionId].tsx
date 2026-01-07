/**
 * Action Modal Route - Dynamic action modal based on actionId
 * Accessed via /action/{actionId}?emailId={emailId}&context={json}
 */

import React, { useEffect, useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { DynamicActionModal } from '../../components/DynamicActionModal';

export default function ActionModalScreen() {
  const { actionId, emailId, context: contextParam } = useLocalSearchParams<{
    actionId: string;
    emailId: string;
    context?: string;
  }>();
  const router = useRouter();
  const [visible, setVisible] = useState(true);

  // Parse context from URL params
  const context = React.useMemo(() => {
    if (!contextParam) return {};
    try {
      return JSON.parse(decodeURIComponent(contextParam));
    } catch {
      return {};
    }
  }, [contextParam]);

  const handleClose = () => {
    setVisible(false);
    router.back();
  };

  const handleSuccess = () => {
    // Could add success animation or notification here
    console.log('Action completed successfully');
  };

  if (!actionId || !emailId) {
    // Redirect back if missing required params
    useEffect(() => {
      router.back();
    }, []);
    return null;
  }

  return (
    <View style={styles.container}>
      <DynamicActionModal
        visible={visible}
        actionId={actionId}
        emailId={emailId}
        context={context}
        onClose={handleClose}
        onSuccess={handleSuccess}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'transparent',
  },
});
