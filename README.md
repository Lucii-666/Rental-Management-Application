<!-- Header Section with Animated Wave -->
<div align="center">
  
<img src="https://capsule-render.vercel.app/api?type=waving&color=00B4D8&height=150&section=header&text=Rent%20Collect%202.0&fontSize=40&animation=twinkling&fontColor=ffffff" width="100%"/>

<h1>🏢</h1>

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Space+Grotesk&weight=700&size=26&pause=1000&color=00B4D8&center=true&vCenter=true&width=800&height=50&lines=Seamless+Property+Management%3A+Evolved;Zero-Latency+Rent+Collection;Real-Time+Push+Notifications;Powered+by+Flutter+%26+Supabase)](https://git.io/typing-svg)

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white&labelColor=222" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black&labelColor=222" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white&labelColor=222" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Deno-000000?style=for-the-badge&logo=deno&logoColor=white&labelColor=222" /></a>
</p>

*The ultimate ecosystem bridging the gap between Property Owners and Tenants with enterprise-level security and real-time syncing.*

<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4520-a447-11eb-908a-139a6edaec5c.gif" width="100%">

</div>

## 🌟 Why Rent Collect?
<h2>🚀</h2>

Managing properties and tracking rent shouldn't require manual ledgers, missing WhatsApp messages, and delayed bank statements. **Rent Collect** is designed to completely automate and track the entire lifecycle of a tenancy—from joining a room to paying the final rent bill, seamlessly.

---

## 🏗️ Core Architecture & Features

### 1. 🔐 [![Security Layer](https://readme-typing-svg.demolab.com?font=Space+Grotesk&weight=700&size=22&pause=1000&color=00B4D8&vCenter=true&width=400&lines=The+Security+Layer)](https://git.io/typing-svg)
We don't just use standard logins. Our security mesh includes:

- **Phone OTP & Biometric Fallbacks**: Frictionless and secure entry.
- **Role-Based Routing**: Intelligent onboarding that adapts the entire UI based on whether you are an Owner or a Tenant.
- **Document Vault**: Fully secure, encrypted storage where tenants can upload PAN/Aadhaar cards for Owner Verification.

<br>

### 2. ⚡ [![Lightning Network](https://readme-typing-svg.demolab.com?font=Space+Grotesk&weight=700&size=22&pause=1000&color=00B4D8&vCenter=true&width=500&lines=The+Lightning+Network+(Push+%26+Sync))](https://git.io/typing-svg)
Manual pull-to-refresh is a thing of the past:

- **Supabase Edge Functions**: We wrote a custom Deno-based Edge Function that instantly translates database writes into OS-level Push Notifications.
- **Zero-Refresh UI**: The moment an Owner marks rent as "Paid", the Tenant's screen updates instantly via Firebase socket streams.
- **Context-Aware Dashboards**: Tenant dashboards physically transform from "Exploring" to "Waiting" to "Active" based on hidden backend approvals.

<br>

### 3. 💵 [![Financial Engine](https://readme-typing-svg.demolab.com?font=Space+Grotesk&weight=700&size=22&pause=1000&color=00B4D8&vCenter=true&width=400&lines=The+Financial+Engine)](https://git.io/typing-svg)
The crown jewel of the application.

- **Batch Generation**: Owners can tap a single button to generate expected rent records for 500+ tenants simultaneously.
- **Algorithmic Overdue Detection**: Built-in chron-logic parses due dates and visually flags rent as overdue on the dashboards.
- **One-Tap Reminders**: Press a button to ping a tenant's lock screen demanding overdue payments.

<br><br>

<div align="center">
<img src="https://user-images.githubusercontent.com/73097560/115834477-dbab4520-a447-11eb-908a-139a6edaec5c.gif" width="100%">

### 🌊 Flow & Logic
```mermaid
graph TD
    A[Property Owner] -->|Creates| B(Property & Room)
    B -->|Generates| C{6-Digit Secret Code}
    D[Tenant] -->|Enters Code| C
    C -->|Sends Request| A
    A -->|Approves| E((Active Tenancy))
    E -->|Edge Function Triggers| F[Push Notification to Tenant!]
    E -->|At Start of Month| G[Rent Automatically Tracked]
```
</div>

## 🎨 Visual Preview

<details>
<summary><b>Click to reveal the power of the UI 📸</b></summary>
<br>

*We are currently undergoing a massive 3D Glassmorphism UI Revamp. Stay tuned for highly animated, 60fps polished screenshots!*

</details>

## 🛠 Develop & Run
<h2>💻</h2>

1. Clone the repository
2. Run `flutter pub get`
3. Link your Supabase CLI for edge functions:  
   `npx supabase link --project-ref gjfunvewcbxpmdfnyunv`
4. Deploy the notification function:  
   `npx supabase functions deploy send-push`
5. Hit `flutter run`!

<div align="center">
  <br>
  <img src="https://capsule-render.vercel.app/api?type=waving&color=00B4D8&height=100&section=footer&animation=twinkling" width="100%"/>
</div>
