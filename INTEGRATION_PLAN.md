# Class Attic × Zulip Integration Plan

Zulip is the **school/class collaboration layer**. Class Attic remains the **marketplace, identity, object, payment, and permissions system of record**.

## Structure

- **One Zulip server** — `chat.classattic.com`
- **One Zulip organization per school** — e.g. `deerfield.chat.classattic.com`
- **One private channel per graduating class** — e.g. `class-of-1998`
- **One topic per object, reunion project, collection theme, or transaction discussion**
- **Class Attic object pages link directly into the matching Zulip topic**
- **A Zulip bot posts object updates, sale status, provenance questions, and reunion prompts**

## Information Architecture

| Layer | Class Attic Concept | Zulip Concept |
| --------------------- | -------------------------------- | ----------------------------- |
| Platform | classattic.com | Zulip server |
| School | Deerfield High School | Zulip organization |
| Class year | Deerfield Class of 1998 | Private channel |
| Object listing | 1998 varsity jacket | Topic |
| Transaction activity | Offers, questions, sold status | Bot messages in topic |
| Alumni identity | Verified Class Attic profile | Zulip user + group membership |
| Cross-year discussion | School lore, reunions, memorabilia | Shared school channels |

## Example

```
Server:       chat.classattic.com
Organization: deerfield.chat.classattic.com

Channels:
  class-of-2026
  class-of-2025
  class-of-1998
  school-marketplace
  reunion-planning
  yearbooks-and-photos

Topic:        "DHS 1998 varsity jacket · item_8F21"
Object URL:   classattic.com/items/8F21 → "Discuss with classmates" → Zulip topic
```

## Why One Organization Per School (Not Per Class)

One org per class fragments the alumni network, makes cross-year discovery harder, creates admin overhead, and prevents useful schoolwide spaces (marketplace, reunions, teachers, sports, yearbooks). Private class channels provide enough isolation.

## Integration Model

Class Attic integrates with Zulip through **API calls and bots** — Zulip is not the app database.

| Event | Action |
| ----------------------------- | ------------------------------------------------ |
| Listing created | Class Attic creates/updates a Zulip topic |
| Listing status changes | Bot posts into the relevant topic |
| Item sells | Bot posts "sold" / "claimed" update |
| User clicks "Discuss" | Routed to the exact Zulip topic |
| Bot command in Zulip | Outgoing webhook notifies Class Attic |
| Payments, identity, disputes | Stay inside Class Attic |

## Object Schema Additions

```json
{
  "zulip_org_id": "string",
  "zulip_channel_id": "integer",
  "zulip_topic": "string",
  "zulip_root_message_id": "integer",
  "chat_visibility": "classmates_only | school | public",
  "allowed_class_years": [1998, 1999]
}
```

## User Provisioning Flow

1. User signs up on Class Attic
2. User claims school and class year
3. Class Attic applies verification rules
4. Class Attic creates or invites the Zulip user via API
5. Class Attic subscribes user to their private class channel and shared school channels

## Access Control

| Role | Access |
| -------------------- | -------------------------------------------------- |
| Public visitor | View object pages on Class Attic only |
| Verified classmate | Class-year Zulip channels |
| School alumni | Schoolwide Zulip channels |
| Seller | Administer their object topics via Class Attic |
| Moderator | Manage school organization health |
| Admin | Manage Zulip orgs, channels, bots, permissions |

## The Core Value Proposition

> **Every object has a living alumni thread.**

Classmates can add:
- "I remember who wore this."
- "That was from the 1997 playoff season."
- "This photo was taken outside the old gym."
- "That jacket belonged to my brother's class."
- "This should be displayed at the reunion."

This turns a listing into a **provenance-building social object** — materially stronger than a normal marketplace listing.

## MVP Scope

### Boundaries
- Deerfield High School only
- Classes 2026–2016
- One Zulip organization
- One channel per class year + one shared marketplace channel
- One bot integration
- Object pages link to Zulip topics
- Only verified users can post
- All buying/selling remains on Class Attic

### Implementation Steps

#### Step 1: Multi-org Zulip (server config)
- Enable `REALM_CREATION` on the Zulip server
- Create the Deerfield organization at `deerfield.chat.classattic.com`
- Configure wildcard DNS (`*.chat.classattic.com → classattic.exe.xyz`)
- Create class-year channels and schoolwide channels

#### Step 2: Bot setup
- Create a "Class Attic" bot user in the Deerfield org
- Generate bot API key
- Store bot credentials in Class Attic's environment (Vercel)
- Bot posts listing summaries, provenance questions, sale status
- Bot messages link back to canonical Class Attic object pages

#### Step 3: Class Attic API integration (Vercel app)
- Add Zulip fields to object schema (`zulip_org_id`, `zulip_channel_id`, `zulip_topic`, `zulip_root_message_id`)
- On listing create → call Zulip API to create topic + post summary
- On listing update → post status change to topic
- On listing sold → post sold notice
- Add "Discuss with classmates" button to object pages → deep-link to Zulip topic

#### Step 4: User provisioning
- On Class Attic signup + school/class verification → create Zulip user via API
- Subscribe user to their class-year channel + schoolwide channels
- SSO via shared auth (Google OAuth2 is already configured on both)

#### Step 5: Outgoing webhooks (Zulip → Class Attic)
- Configure Zulip outgoing webhook for bot mentions
- Class Attic receives commands like `@class-attic status item_8F21`
- Class Attic responds with current listing info

## Zulip API Reference

| Operation | Endpoint |
| ----------------------- | ---------------------------------------------- |
| Create user | `POST /api/v1/users` |
| Send message | `POST /api/v1/messages` |
| Create channel | `POST /api/v1/users/me/subscriptions` |
| Subscribe user | `POST /api/v1/users/me/subscriptions` |
| Get channel topics | `GET /api/v1/users/me/{stream_id}/topics` |
| Update message / topic | `PATCH /api/v1/messages/{msg_id}` |
| Register event queue | `POST /api/v1/register` |
| Outgoing webhooks | Configured in Zulip org settings |

Base URL: `https://chat.classattic.com/api/v1/` (or per-org subdomain)

Docs: https://zulip.com/api/

## Architecture Decision

Zulip is **Class Attic's alumni coordination substrate**, not a replacement for marketplace infrastructure.

```
┌─────────────────────┐         ┌──────────────────────┐
│   classattic.com    │         │  chat.classattic.com │
│   (Vercel)          │◄───────►│  (Zulip / Docker)    │
│                     │  API    │                      │
│ • Listings          │  Bot    │ • Organizations      │
│ • Payments          │  Links  │ • Channels           │
│ • Identity          │         │ • Topics             │
│ • Verification      │         │ • Threads            │
│ • Disputes          │         │ • Bot messages       │
└─────────────────────┘         └──────────────────────┘
```
