# Mock Email Fixtures

This directory contains JSON fixtures for mock email data used in testing and development.

## Structure

```
MockEmails/
├── newsletters/      # Newsletter emails (tech, shopping, etc.)
├── receipts/         # Purchase receipts and confirmations
├── travel/           # Flight confirmations, hotel bookings
├── packages/         # Package tracking and delivery
├── events/           # Event invitations, RSVPs
├── bills/            # Utility bills, invoices
├── subscriptions/    # Subscription renewals, upgrades
├── food/             # Food delivery, restaurant reservations
├── education/        # School forms, parent communications
├── finance/          # Banking, investments, loans
├── health/           # Medical appointments, prescriptions
├── professional/     # Work-related, contracts
├── social/           # Social media notifications
├── entertainment/    # Streaming, gaming, media
├── security/         # Security alerts, 2FA codes
└── schema.json       # JSON schema definition
```

## Schema

Each mock email JSON file follows the `MockEmailSchema` defined in `schema.json`.

See `schema.json` for complete field definitions and examples.

## Usage

```swift
// Load a specific mock email
let loader = MockDataLoader()
let email = try loader.loadEmail(from: "newsletters/tech_weekly")

// Load all emails from a category
let newsletters = try loader.loadCategory("newsletters")

// Load all mock emails
let allEmails = try loader.loadAllEmails()
```

## Adding New Mock Emails

1. Create a JSON file in the appropriate category folder
2. Follow the schema defined in `schema.json`
3. Validate with `MockDataLoader.validate()`
4. Add to the appropriate test case

## File Naming Convention

- Use snake_case for filenames
- Use descriptive names: `newsletter_tech_weekly.json`, `receipt_amazon_books.json`
- Include variant if multiple versions: `flight_confirmation_international.json`
