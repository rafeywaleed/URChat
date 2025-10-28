<div align="center">

# 🎮 **URChat**  
### _Retro Vibes • Real-Time Tech • Cross-Platform Messaging_

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black)
![Vercel](https://img.shields.io/badge/Vercel-000000.svg?style=for-the-badge&logo=vercel&logoColor=white)

---

### 🖥️ Desktop Demo  
https://github.com/user-attachments/assets/1c3079a8-68ab-49a1-b9e2-95fe264923b5  

### 📱 Mobile Demo  

https://github.com/user-attachments/assets/9b862758-3a98-4a17-ba8b-fd088a879eff


---

</div>

## 🕹️ **Overview**

**URChat** reimagines the nostalgic charm of NES-era visuals as a **modern, real-time chat app**, minimal, performant, and full of personality.  
It’s a full-stack system built for the web and mobile world, blending **retro design**, **real-time tech**, and **cross-platform accessibility**.

> 💡 _Fast. Fun. Functional. URChat is lightweight yet loaded with powerful features._

---

## ✨ **Core Highlights**

| Feature | Description |
|:--------|:-------------|
| 💬 **Real-Time Messaging** | Instant delivery powered by **Spring WebSockets** + **PostgreSQL** |
| 🔔 **Smart Notifications** | Sent directly through **Spring Boot (FCM Admin)** |
| 🔐 **JWT Auth System** | Secure Access + Refresh token-based authentication |
| 📧 **SMTP Integration** | Email verification & password recovery |
| 🧩 **Cross-Platform UI** | **Flutter** ensures seamless Web + Android experience |
| 🎨 **Dynamic Chat Themes** | _Simple_, _Modern Elegant_, _Cute_. each with **Light & Dark** variants |
| 😀 **Emoji-Based Profiles** | No profile pics, expressive **animated emojis** & color-coded backgrounds |
| 🧑‍🤝‍🧑 **DM & Group Chats** | Supports **admin controls** and real-time group updates |
| 🔍 **User Search** | Find and connect with users instantly |
| 🕹️ **Offline Mini-Game** | Built-in **AI-generated maze chase game** playable offline |
| 🧹 **Auto Message Cleanup** | Deletes messages after **7 days** (for free-tier optimization) |
| ⚡ **In-App Notifications** | Fun, animated alerts right inside the chat |
| ☁️ **Optimized Backend** | Minimal resource usage for fast performance |

---

## 🧠 **Tech Stack**

### 🖥️ **Backend**
| Component | Description |
|------------|--------------|
| ⚙️ **Spring Boot** | Core backend framework |
| 🧵 **Spring WebSockets** | Real-time messaging channel |
| 🔐 **Spring Security (JWT)** | Access & Refresh token authentication |
| 🗃️ **JPA + Hibernate** | ORM for PostgreSQL |
| 📨 **Firebase Admin SDK** | Handles push notifications |
| ✉️ **JavaMail (SMTP)** | For verification and recovery emails |

### 📱 **Frontend**
| Component | Description |
|------------|--------------|
| 💙 **Flutter** | Single codebase for Web + Mobile |
| 🔥 **Firebase Messaging** | Client-side notification handler |
| 💾 **SharedPreferences** | Local caching for message persistence |
| 🎨 **Custom Theme Engine** | Per-chat dynamic theming |
| 🧸 **Animated Emojis + NES UI** | Retro-styled, fun visual language |

---

## 🧩 **Architecture**

```text
┌────────────────────────┐       ┌────────────────────────┐
│       Flutter App      │◄────►│     Spring Boot API     │
│ (Web + Android Client) │       │ (WebSocket + REST + FCM)│
└────────────┬───────────┘       └────────────┬───────────┘
             │                               │
             ▼                               ▼
     Firebase Cloud Msg.            PostgreSQL Database


