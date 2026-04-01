# Set Up SES Prerequisites

Set up Amazon SES once per AWS account and region where your notifier Lambda runs. AWS now guides much of this in the SES setup wizard; this page is the short checklist for LambdaCron.


## When to Use

* You want to use Amazon SES as the delivery provider for LambdaCron email notifications.
* You have not yet prepared SES identities or account access in the target AWS region.

## Before You Begin

* Choose the AWS account/region where email will be sent (SES setup is regional).
* Choose a sender identity:

  * Email identity for one sender address.
  * Domain identity if you want to send from multiple addresses in one domain.

* Make sure you can edit DNS records if you choose a domain identity.

SES requires verified identities for senders and (in sandbox) recipients. That means you must verify the email address or domain you want to send from, and if in sandbox, also verify any recipient addresses. Sandbox mode limits how much you can send, and you'll probably want to request production access if you want to send to more than one recipient.

## Steps

1. Open Amazon SES in the notifier's region and follow the setup flow.
   * Start with AWS's setup guide and wizard: <https://docs.aws.amazon.com/ses/latest/dg/setting-up.html>.
2. Create and verify your sender identity.
   * SES requires verified identities for `From`/`Sender` addresses.
   * Use the verified identities guide: <https://docs.aws.amazon.com/ses/latest/dg/verify-addresses-and-domains.html>.
   * If using a domain, publish SES-provided DNS records (including DKIM) and wait for `Verified`.
3. Account for sandbox restrictions while testing.
   * New SES accounts are in sandbox mode per region.
   * In sandbox, you can only send to verified recipients (or the SES mailbox simulator).
4. Request production access when you are ready to send to unverified recipients.
   * Submit a production access request in the same region: <https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html>.
   * Keep your verified sender identity in place after approval.
5. (Recommended) Publish SPF/DMARC records for your sending domain to improve deliverability.
6. Send a test email from SES in that region before deploying the notifier.
   * Use the exact sender address you plan to configure in the `email-notification` module.

## Validation

* SES identity status is `Verified` for your sender.
* All required tasks are completed on the SES console's "Get set up" page.
* If still in sandbox, all test recipients are verified.
* If in production, you can send to non-verified recipients.
* A console/API test send succeeds in the same region as your notifier Lambda.
