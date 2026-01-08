/**
 * Mock email data for demo feed
 * Matches the Zero web demo styling and intents
 */

import type { EmailCard } from '@zero/types';

export const MOCK_MAIL_EMAILS: EmailCard[] = [
  {
    id: 'mail-1',
    type: 'mail',
    title: 'Your Amazon order has shipped',
    summary: 'Your order #112-4892736-2847382 containing "Apple AirPods Pro (2nd generation)" has shipped and is on its way! Estimated delivery is Thursday, January 9th.',
    sender: {
      name: 'Amazon',
      email: 'shipment-tracking@amazon.com',
      initial: 'A',
      domain: 'amazon.com',
    },
    timeAgo: '2h',
    priority: 'medium',
    intent: 'e-commerce.shipping.tracking',
    intentConfidence: 0.94,
    hpa: 'Track Package',
    suggestedActions: [
      { id: 'track', type: 'open_url', displayName: 'Track Package', isPrimary: true },
      { id: 'archive', type: 'archive', displayName: 'Archive' },
    ],
    context: {
      orderNumber: '#112-4892736-2847382',
      carrier: 'UPS',
      estimatedDelivery: 'Thursday, Jan 9',
    },
    aiGeneratedSummary: 'Your AirPods Pro are on the way - arriving Thursday.',
  },
  {
    id: 'mail-2',
    type: 'mail',
    title: 'Security Alert: New sign-in detected',
    summary: 'We noticed a new sign-in to your Google Account from a Mac device in New York, United States. If this was you, you can safely ignore this email.',
    sender: {
      name: 'Google',
      email: 'no-reply@accounts.google.com',
      initial: 'G',
      domain: 'google.com',
    },
    timeAgo: '35m',
    priority: 'critical',
    intent: 'security.alert.login',
    intentConfidence: 0.98,
    hpa: 'Review Activity',
    suggestedActions: [
      { id: 'review', type: 'open_url', displayName: 'Review Activity', isPrimary: true },
      { id: 'secure', type: 'open_url', displayName: 'Secure Account' },
    ],
    context: {
      device: 'Mac',
      location: 'New York, US',
      time: 'January 7, 2026 at 2:35 PM',
    },
    aiGeneratedSummary: 'New login from Mac in NYC - verify this was you.',
    isVIP: true,
  },
  {
    id: 'mail-3',
    type: 'mail',
    title: 'Invoice #INV-2024-0891 is due soon',
    summary: 'This is a reminder that your invoice from Vercel for $29.00 is due on January 15, 2024. Please ensure payment is made before the due date to avoid late fees.',
    sender: {
      name: 'Vercel',
      email: 'billing@vercel.com',
      initial: 'V',
      domain: 'vercel.com',
    },
    timeAgo: '1d',
    priority: 'high',
    intent: 'billing.invoice.reminder',
    intentConfidence: 0.91,
    hpa: 'Pay Invoice',
    suggestedActions: [
      { id: 'pay', type: 'open_url', displayName: 'Pay $29.00', isPrimary: true },
      { id: 'snooze', type: 'snooze', displayName: 'Remind Later' },
    ],
    context: {
      amount: '$29.00',
      dueDate: 'January 15, 2024',
      invoiceNumber: 'INV-2024-0891',
    },
    hasAttachments: true,
  },
  {
    id: 'mail-4',
    type: 'mail',
    title: 'Your Uber ride receipt',
    summary: 'Thanks for riding with Uber! Your trip from Manhattan to Brooklyn on Jan 6 cost $24.50. View your receipt for trip details and rate your driver.',
    sender: {
      name: 'Uber',
      email: 'receipts@uber.com',
      initial: 'U',
      domain: 'uber.com',
    },
    timeAgo: '3h',
    priority: 'low',
    intent: 'billing.receipt.transportation',
    intentConfidence: 0.89,
    hpa: 'View Receipt',
    suggestedActions: [
      { id: 'view', type: 'open_url', displayName: 'View Receipt', isPrimary: true },
      { id: 'archive', type: 'archive', displayName: 'Archive' },
    ],
    context: {
      amount: '$24.50',
      from: 'Manhattan',
      to: 'Brooklyn',
    },
  },
  {
    id: 'mail-5',
    type: 'mail',
    title: 'Team standup notes - January 7',
    summary: 'Here are the notes from today\'s standup: Matt is working on the mobile card layout, Sarah is fixing auth bugs, and Alex is preparing the Q4 deck.',
    sender: {
      name: 'Notion',
      email: 'notifications@makenotion.com',
      initial: 'N',
      domain: 'notion.so',
    },
    timeAgo: '4h',
    priority: 'medium',
    intent: 'work.collaboration.notes',
    intentConfidence: 0.86,
    hpa: 'Open in Notion',
    suggestedActions: [
      { id: 'open', type: 'open_url', displayName: 'Open in Notion', isPrimary: true },
      { id: 'archive', type: 'archive', displayName: 'Archive' },
    ],
    context: {
      workspace: 'Zero Team',
      page: 'Standup Notes',
    },
    aiGeneratedSummary: 'Team updates: mobile layout, auth fixes, Q4 prep.',
  },
  {
    id: 'mail-6',
    type: 'mail',
    title: 'Re: Project timeline discussion',
    summary: 'Hey Matt, I reviewed the timeline and I think we can push the alpha release to next Friday if we focus on the core features first. Let me know what you think.',
    sender: {
      name: 'Sarah Chen',
      email: 'sarah@company.com',
      initial: 'S',
      domain: 'company.com',
    },
    timeAgo: '1h',
    priority: 'high',
    intent: 'work.email.reply_needed',
    intentConfidence: 0.92,
    hpa: 'Reply',
    suggestedActions: [
      { id: 'reply', type: 'quick_reply', displayName: 'Reply', isPrimary: true },
      { id: 'snooze', type: 'snooze', displayName: 'Remind Later' },
    ],
    context: {
      threadSubject: 'Project timeline discussion',
      threadCount: 5,
    },
    aiGeneratedSummary: 'Sarah suggests pushing alpha to Friday - needs your input.',
    isVIP: true,
    threadCount: 5,
  },
  {
    id: 'mail-7',
    type: 'mail',
    title: 'Your Spotify Wrapped 2024 is here',
    summary: 'You listened to 42,891 minutes of music this year! Your top artist was The Weeknd with 2,847 minutes played. Discover your full listening report.',
    sender: {
      name: 'Spotify',
      email: 'noreply@spotify.com',
      initial: 'S',
      domain: 'spotify.com',
    },
    timeAgo: '5h',
    priority: 'low',
    intent: 'newsletter.entertainment.personalized',
    intentConfidence: 0.88,
    hpa: 'View Wrapped',
    suggestedActions: [
      { id: 'view', type: 'open_url', displayName: 'View Wrapped', isPrimary: true },
      { id: 'archive', type: 'archive', displayName: 'Archive' },
    ],
    isNewsletter: true,
  },
  {
    id: 'mail-8',
    type: 'mail',
    title: 'Action required: Verify your new phone',
    summary: 'You recently added a new phone to your Apple ID. Please verify this device by entering the code sent to your trusted devices.',
    sender: {
      name: 'Apple',
      email: 'noreply@id.apple.com',
      initial: 'A',
      domain: 'apple.com',
    },
    timeAgo: '20m',
    priority: 'critical',
    intent: 'security.two_factor.device_add',
    intentConfidence: 0.97,
    hpa: 'Verify Device',
    suggestedActions: [
      { id: 'verify', type: 'open_url', displayName: 'Verify Device', isPrimary: true },
      { id: 'not_me', type: 'open_url', displayName: 'Not Me' },
    ],
    context: {
      device: 'iPhone 15 Pro',
      location: 'New York, NY',
    },
    aiGeneratedSummary: 'New iPhone added to your Apple ID - verify now.',
  },
];

export const MOCK_ADS_EMAILS: EmailCard[] = [
  {
    id: 'ads-1',
    type: 'ads',
    title: '🎉 50% off all winter styles - Flash Sale!',
    summary: 'Beat the cold with our biggest winter sale ever! Get 50% off coats, sweaters, and boots. Use code WINTER50 at checkout. Ends midnight tonight!',
    sender: {
      name: 'Nordstrom',
      email: 'deals@e.nordstrom.com',
      initial: 'N',
      domain: 'nordstrom.com',
    },
    timeAgo: '1h',
    priority: 'medium',
    intent: 'marketing.promotion.sale',
    intentConfidence: 0.95,
    hpa: 'Shop Sale',
    suggestedActions: [
      { id: 'shop', type: 'open_url', displayName: 'Shop Sale', isPrimary: true },
      { id: 'unsubscribe', type: 'unsubscribe', displayName: 'Unsubscribe' },
    ],
    context: {
      discount: '50%',
      code: 'WINTER50',
      expires: 'Tonight',
    },
    isNewsletter: true,
  },
  {
    id: 'ads-2',
    type: 'ads',
    title: 'You left something in your cart 👀',
    summary: 'Those Nike Air Max 90s are still waiting for you! Complete your purchase now and get free shipping. Don\'t miss out - only 3 left in your size.',
    sender: {
      name: 'Nike',
      email: 'store@nike.com',
      initial: 'N',
      domain: 'nike.com',
    },
    timeAgo: '4h',
    priority: 'low',
    intent: 'e-commerce.cart.abandoned',
    intentConfidence: 0.93,
    hpa: 'Complete Purchase',
    suggestedActions: [
      { id: 'buy', type: 'open_url', displayName: 'Complete Purchase', isPrimary: true },
      { id: 'remove', type: 'archive', displayName: 'Not Interested' },
    ],
    context: {
      product: 'Nike Air Max 90',
      stock: '3 left',
    },
  },
  {
    id: 'ads-3',
    type: 'ads',
    title: 'Your weekly digest from The Morning Brew ☕',
    summary: 'This week: Fed signals rate cuts, Apple unveils Vision Pro sales data, and why everyone\'s talking about the new AI chip wars.',
    sender: {
      name: 'Morning Brew',
      email: 'crew@morningbrew.com',
      initial: 'M',
      domain: 'morningbrew.com',
    },
    timeAgo: '6h',
    priority: 'low',
    intent: 'newsletter.digest.weekly',
    intentConfidence: 0.96,
    hpa: 'Read Newsletter',
    suggestedActions: [
      { id: 'read', type: 'open_url', displayName: 'Read Now', isPrimary: true },
      { id: 'unsubscribe', type: 'unsubscribe', displayName: 'Unsubscribe' },
    ],
    isNewsletter: true,
  },
  {
    id: 'ads-4',
    type: 'ads',
    title: 'Exclusive: 3 months of Apple TV+ on us',
    summary: 'As a valued customer, enjoy 3 months of Apple TV+ absolutely free. Stream award-winning originals like Severance, Ted Lasso, and more.',
    sender: {
      name: 'Apple',
      email: 'promo@apple.com',
      initial: 'A',
      domain: 'apple.com',
    },
    timeAgo: '2d',
    priority: 'low',
    intent: 'marketing.promotion.trial',
    intentConfidence: 0.91,
    hpa: 'Activate Free Trial',
    suggestedActions: [
      { id: 'activate', type: 'open_url', displayName: 'Activate Free Trial', isPrimary: true },
      { id: 'dismiss', type: 'archive', displayName: 'Dismiss' },
    ],
    context: {
      offer: '3 months free',
      service: 'Apple TV+',
    },
  },
  {
    id: 'ads-5',
    type: 'ads',
    title: '🔥 Cyber Monday Extended: 40% off everything',
    summary: 'By popular demand, we\'ve extended our Cyber Monday sale! Get 40% off sitewide with code CYBER40. Plus, free 2-day shipping on all orders.',
    sender: {
      name: 'Everlane',
      email: 'deals@everlane.com',
      initial: 'E',
      domain: 'everlane.com',
    },
    timeAgo: '8h',
    priority: 'medium',
    intent: 'marketing.promotion.sale',
    intentConfidence: 0.94,
    hpa: 'Shop Now',
    suggestedActions: [
      { id: 'shop', type: 'open_url', displayName: 'Shop Now', isPrimary: true },
      { id: 'unsubscribe', type: 'unsubscribe', displayName: 'Unsubscribe' },
    ],
    context: {
      discount: '40%',
      code: 'CYBER40',
    },
    isNewsletter: true,
  },
  {
    id: 'ads-6',
    type: 'ads',
    title: 'New episode: How I Built This with Guy Raz',
    summary: 'This week: The founder of Notion talks about building the future of productivity tools and the challenges of scaling a $10B company.',
    sender: {
      name: 'NPR',
      email: 'podcasts@npr.org',
      initial: 'N',
      domain: 'npr.org',
    },
    timeAgo: '12h',
    priority: 'low',
    intent: 'newsletter.content.podcast',
    intentConfidence: 0.89,
    hpa: 'Listen Now',
    suggestedActions: [
      { id: 'listen', type: 'open_url', displayName: 'Listen Now', isPrimary: true },
      { id: 'archive', type: 'archive', displayName: 'Archive' },
    ],
    isNewsletter: true,
  },
];

// Combined and shuffled for realistic inbox feel
export const ALL_MOCK_EMAILS: EmailCard[] = [
  MOCK_MAIL_EMAILS[1], // Security alert (critical)
  MOCK_MAIL_EMAILS[7], // Apple verify (critical)
  MOCK_MAIL_EMAILS[5], // Sarah email (high priority, needs reply)
  MOCK_MAIL_EMAILS[2], // Invoice due (high)
  MOCK_MAIL_EMAILS[0], // Amazon shipping
  MOCK_ADS_EMAILS[0],  // Nordstrom sale
  MOCK_MAIL_EMAILS[4], // Standup notes
  MOCK_MAIL_EMAILS[3], // Uber receipt
  MOCK_ADS_EMAILS[1],  // Nike cart
  MOCK_MAIL_EMAILS[6], // Spotify wrapped
  MOCK_ADS_EMAILS[2],  // Morning Brew
  MOCK_ADS_EMAILS[4],  // Everlane sale
  MOCK_ADS_EMAILS[3],  // Apple TV+
  MOCK_ADS_EMAILS[5],  // NPR podcast
];

export function getMockEmails(type?: 'mail' | 'ads'): EmailCard[] {
  if (type === 'mail') return MOCK_MAIL_EMAILS;
  if (type === 'ads') return MOCK_ADS_EMAILS;
  return ALL_MOCK_EMAILS;
}


