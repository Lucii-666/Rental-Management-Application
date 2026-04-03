<div align="center">

<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Buildings/House%20with%20Garden.png" alt="House with Garden" width="100" height="100" />

# Rent Collect 🏢

[![Typing SVG](https://readme-typing-svg.demolab.com?font=Space+Grotesk&weight=700&size=30&pause=1000&color=00B4D8&center=true&vCenter=true&width=800&height=50&lines=Seamless+Property+Management;Real-time+Rent+Collection;Built+with+Flutter+%26+Firebase)](https://git.io/typing-svg)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
</p>

A professional, real-time ecosystem connecting **Property Owners** and **Tenants** through an intelligent synchronization layer.

[Explore Features](#-module-1-foundation--authentication) • [Installation (WIP)](#) • [Tech Stack](#-technical-stack)

<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Line.png" alt="Line separator" width="100%" />

</div>

## 📦 Module 1: Foundation & Authentication
<img align="right" src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Locked%20with%20Pen.png" alt="Locked" width="80" />

*The secure gateway and user identity management system.*

### 🛡️ Authentication Features
- **Phone Number + OTP**: Seamless registration via mobile verification.
- **Email & Password**: Traditional secure login flow.
- **Role Selection**: Intent-based onboarding (`Owner` or `Tenant`).
- **Real-time Sessions**: Persistent login states that survive app restarts.

### 👤 Profile Management
- **Dynamic Profiles**: Editable metadata (Name, Bio, Contact).
- **Biometric/Visual ID**: Integrated camera/gallery for profile photos.
- **Avatar Storage**: Direct integration with Firebase/Supabase Storage.

<br>

## 🏠 Module 2: Dashboards & Sync
<img align="right" src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Mobile%20Phone.png" alt="Phone" width="80" />

*The operational core providing instant feedback and connectivity.*

### 📊 Owner Dashboard
- **Instant Stats**: Real-time counters for Properties, Rooms, and Tenants.
- **Occupancy Insights**: Visual breakdown of room statuses.

### 🏘️ Tenant Dashboard
- **Context-Aware UI**: Adapts dynamically (No Property Explorer -> Pending Request -> Active Tenant Hub).

### 🔔 Real-time Communication
- **Global Push Notifications**: Integrated Firebase Cloud Messaging via Supabase Edge Functions.
- **Unread Badges**: Real-time counters on navigation bars.
- **Zero-Refresh**: Tenant screens update instantly when an owner acts.

<br>

## 🛠️ Module 3: Property Operations
<img align="right" src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Wrench.png" alt="Wrench" width="80" />

*The business logic layer where property management happens.*

### 🏫 Property & Room Engine
- **Property Studio**: Owners create properties.
- **Room Architect**: Define limits, rent amounts, and statuses.
- **Join Logic**: Generates secure 6-digit codes for private invites.

### 📑 Request & Verification Hub
- **The Decider**: Owners review tenant bios and `Approve/Reject` seamlessly.
- **Document Verification**: Tenants upload KYC (Aadhaar/PAN); owners verify with a smooth UI.
- **Issue Reporting**: Tenants report maintenance with text and camera uploads.

<br>

## 💰 Module 4: Rent Collection
<img align="right" src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Money%20Bag.png" alt="Money" width="80" />

*The financial engine — the feature the entire app is built around.*

### 🧾 Smart Record Generation
- **One-Tap Generation**: Generate rent for all tenants across properties instantly.
- **Overdue Detection**: Built-in intelligence marks missed payments.
- **Room-Linked Amounts**: Automatically syncs rent with predefined room costs.

### 📊 Revenue Dashboard
- **Live Totals**: Visual summary of `Expected`, `Collected`, and `Pending`.
- **Rent Reminders**: One-tap push notifications to trigger reminders.

<br>

<div align="center">
<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Line.png" alt="Line separator" width="100%" />

### 🚀 Technical Stack

<img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" /> <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" /> <img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black" /> <img src="https://img.shields.io/badge/Supabase%20Edge%20Functions-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />

*Status: Modules 1, 2, 3, and 4 are complete and ready for deployment.*

</div>
