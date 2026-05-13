# IT Ticket Tracking

This file tracks IT tickets submitted for configuration changes and their resolutions.

---

## IMS0388231 - Configure Microsoft Outlook as Default mailto: Handler

**Status:** 🟡 Open - Awaiting Response

**Submitted:** 2026-05-12

**Category:** System Configuration / macOS Settings

**Priority:** Medium

**Impact:** Individual (affects all Mac users)

### Issue Summary

mailto: links on macOS attempt to open Apple Mail instead of Microsoft Outlook, despite Outlook being the required company email client. Configuration Profile enforces Apple Mail as the handler, preventing user-level changes.

### Requested Resolution

**Option 1 (Preferred):** Modify Configuration Profile to default to Microsoft Outlook
- Change mailto: handler from `com.apple.mail` to `com.microsoft.Outlook`
- Sets Outlook as default for all Mac users

**Option 2 (Alternative):** Allow user-level overrides
- Remove mailto: handler restriction from Configuration Profile
- Allow users to configure preferred mail application

### Technical Details

| Item | Value |
|------|-------|
| Application | Microsoft Outlook |
| Bundle ID | `com.microsoft.Outlook` |
| URL Scheme | `mailto:` |
| Current Handler (enforced) | `com.apple.mail` |
| Desired Handler | `com.microsoft.Outlook` |
| Verification Method | Configuration Profile inspection, LaunchServices testing |

### Business Justification

- Company policy requires Microsoft Outlook (not Apple Mail)
- Apple Mail not configured per policy
- Manual copy/paste workaround reduces productivity
- Microsoft 365 integration requires Outlook

### Current Workaround

Manually copy email addresses from mailto: links and paste into Outlook compose window.

### Timeline

- **2026-05-12:** Ticket submitted (IMS0388231)
- **TBD:** Awaiting IT response

### Resolution (When Completed)

*To be updated when ticket is resolved*

---

## Template for Future Tickets

### TICKET-NUMBER - Brief Description

**Status:** 🟡 Open / 🟢 Resolved / 🔴 Closed - No Action

**Submitted:** YYYY-MM-DD

**Category:** 

**Priority:** 

### Issue Summary

Brief description of the problem.

### Requested Resolution

What you're asking IT to do.

### Technical Details

Relevant technical information for IT to implement the change.

### Timeline

- **YYYY-MM-DD:** Key events

### Resolution

Final outcome and any notes.

---

## Status Legend

- 🟡 **Open** - Ticket submitted, awaiting response
- 🔵 **In Progress** - IT is working on the issue
- 🟢 **Resolved** - Issue fixed, ticket closed
- 🔴 **Closed - No Action** - Ticket closed without resolution
- 🟣 **Awaiting User** - IT needs more information
