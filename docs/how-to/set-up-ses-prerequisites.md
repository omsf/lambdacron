# Set Up SES Prerequisites

## When to Use
- You want to use Amazon SES as the delivery provider for Cloud Cron email notifications.
- You have not yet prepared SES identities or account access in the target AWS region.

## Inputs to Provide
- AWS account and region where SES will send mail.
- Sender identity to verify (single email address or domain).
- DNS control for the sender domain (if using domain identity).

## Steps
1. Open the SES console in the same AWS region where the email notifier runs.
2. Create and verify a sender identity for your use case: verify an email address for a single sender, or verify a domain for broader use.
3. If you verify a domain, publish the SES-provided DKIM DNS records and wait for identity status to become verified.
4. While the account is in SES sandbox mode, verify each recipient address you plan to send to.
5. If you need to send to unverified recipients, request production access for the SES account and region.
6. (Recommended) Publish SPF and DMARC DNS records for domain reputation and deliverability.

## Validation
- SES identity status is `Verified` for your sender.
- If still in sandbox, all test recipients are verified.
- A test send from the SES console succeeds in the target region.
