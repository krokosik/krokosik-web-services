/**
 * Cloudflare Email Worker - Firefly III Email Bridge
 * 
 * Receives forwarded emails from Proton Mail via Cloudflare Email Routing,
 * parses the email content, and forwards to n8n webhook for processing.
 */

import PostalMime from 'postal-mime';

export interface Env {
  N8N_WEBHOOK_URL: string;
  N8N_WEBHOOK_PATH: string;
  WEBHOOK_SECRET: string;
}

interface EmailPayload {
  from: string;
  to: string;
  subject: string;
  date: string;
  htmlBody: string | null;
  textBody: string | null;
  receivedAt: string;
}

export default {
  async email(message: ForwardableEmailMessage, env: Env, ctx: ExecutionContext): Promise<void> {
    console.log(`========== EMAIL RECEIVED ==========`);
    console.log(`From: ${message.from}`);
    console.log(`To: ${message.to}`);
    console.log(`Subject: ${message.headers.get('subject')}`);

    try {
      // Read the raw email content
      const rawEmail = await new Response(message.raw).arrayBuffer();
      
      // Parse the email using postal-mime
      const parser = new PostalMime();
      const parsed = await parser.parse(rawEmail);

      // Extract HTML body (mBank sends HTML emails)
      let htmlBody: string | null = null;
      let textBody: string | null = null;
      let htmlSource: string = 'none';

      // PRIORITY 1: Check for HTML attachments first (mBank sends transaction data as .htm attachment)
      // This takes priority because Proton Mail wraps forwarded emails in its own HTML
      if (parsed.attachments) {
        for (const attachment of parsed.attachments) {
          if (attachment.mimeType === 'text/html' || 
              attachment.filename?.endsWith('.html') || 
              attachment.filename?.endsWith('.htm')) {
            const decoder = new TextDecoder('iso-8859-2'); // mBank uses this encoding
            htmlBody = decoder.decode(attachment.content);
            htmlSource = `attachment: ${attachment.filename}`;
            console.log(`Found HTML attachment: ${attachment.filename} (${attachment.content.byteLength} bytes)`);
            break;
          }
        }
      }

      // PRIORITY 2: Fall back to inline HTML body if no HTML attachment found
      if (!htmlBody && parsed.html) {
        htmlBody = parsed.html;
        htmlSource = 'inline body';
      }
      
      // Extract text body (for reference/logging)
      if (parsed.text) {
        textBody = parsed.text;
      }

      // Log email content for debugging
      console.log(`========== EMAIL CONTENT ==========`);
      console.log(`HTML Source: ${htmlSource}`);
      console.log(`Text Body: ${textBody ? textBody.substring(0, 500) : '(none)'}`);
      console.log(`HTML Body (first 2000 chars): ${htmlBody ? htmlBody.substring(0, 2000) : '(none)'}`);
      console.log(`Attachments: ${parsed.attachments?.length || 0}`);
      if (parsed.attachments) {
        for (const att of parsed.attachments) {
          console.log(`  - ${att.filename} (${att.mimeType}, ${att.content.byteLength} bytes)`);
        }
      }

      // Build the payload for n8n
      const payload: EmailPayload = {
        from: message.from,
        to: message.to,
        subject: message.headers.get('subject') || '',
        date: message.headers.get('date') || new Date().toISOString(),
        htmlBody,
        textBody,
        receivedAt: new Date().toISOString(),
      };

      // Send to n8n webhook
      const webhookUrl = `${env.N8N_WEBHOOK_URL}${env.N8N_WEBHOOK_PATH}`;
      console.log(`========== SENDING TO N8N ==========`);
      console.log(`Webhook URL: ${webhookUrl}`);
      
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': env.WEBHOOK_SECRET,
          'User-Agent': 'Cloudflare-Worker-Firefly-Email-Bridge/1.0',
        },
        body: JSON.stringify(payload),
      });

      console.log(`Response Status: ${response.status}`);
      console.log(`Response Headers: ${JSON.stringify(Object.fromEntries(response.headers))}`);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error(`n8n webhook failed: ${response.status} - ${errorText}`);
      } else {
        const responseText = await response.text();
        console.log(`Success! Response: ${responseText}`);
      }
    } catch (error) {
      console.error(`Error processing email: ${error}`);
    }
    
    console.log(`========== END ==========`);
  },
};
