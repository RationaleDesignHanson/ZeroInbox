const { IntentTaxonomy } = require('./shared/models/Intent');

const testIntents = [
  'healthcare.appointment.booking-request',
  'youth.sports.game-schedule',
  'youth.sports.practice-reminder',
  'content.newsletter.tech',
  'social.notification.message',
  'social.verification.required',
  'real-estate.recommendation.listing',
  'finance.mortgage.communication',
  'generic.newsletter.content',
  'generic.transactional.notification',
  'communication.personal.message'
];

console.log('Checking intents in IntentTaxonomy:\n');
testIntents.forEach(intent => {
  const exists = !!IntentTaxonomy[intent];
  console.log(`${exists ? '✅' : '❌'} ${intent}`);
});

console.log(`\nTotal intents in taxonomy: ${Object.keys(IntentTaxonomy).length}`);
