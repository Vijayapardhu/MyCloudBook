# Software Requirements Specification (SRS)  
## MyCloudBook - AI-Powered Digital Notebook Platform

---

## 1. Introduction

### 1.1 Purpose  
This document details requirements for MyCloudBook, a cross-platform Flutter app that digitizes, organizes, and enhances handwritten notes using Google Gemini AI. It targets students and professionals, enabling handwriting-to-text conversion, AI summarization, collaborative editing, and offline functionality.

### 1.2 Scope  
MyCloudBook supports image uploads of handwritten notes in a timeline, rough work attachments, AI-powered study aids, real-time collaboration, secure API key storage, and seamless offline-online sync, deployed on iOS, Android, and Web with Flutter.

### 1.3 Intended Audience  
App developers, UI/UX designers, AI engineers, project managers, and stakeholders.

---

## 2. General Description

### 2.1 Product Perspective  
Combines Flutter frontend, Supabase backend with PostgreSQL, and Google Gemini AI API using encrypted user-provided keys, creating a connected study environment.

### 2.2 Product Features Summary  
- Daily handwritten page uploads in timeline flow  
- Rough work linked pages and toggle views  
- Gemini AI handwriting recognition, summarization, flashcards, quizzes  
- Real-time collaboration with role-based permissions and chat  
- Offline mode with sync and conflict resolution  
- PDF batch export with customizable options  
- Assignment tracker, Pomodoro timer, LaTeX math editor  
- Encrypted Gemini API key storage, two-factor authentication  

### 2.3 Pricing Model  
**Free Tier:**
- 100 pages/month with AI processing
- 5GB storage per user
- User-provided Gemini API keys (no platform costs for AI)
- Basic features: note upload, timeline, AI conversion, flashcards, collaboration
- Automated quota tracking and alerts

**Premium Tier (Future Enhancement):**
- Unlimited pages per month
- 50GB+ storage
- Priority customer support
- Advanced AI features: concept maps, adaptive quizzes, personalized recommendations
- Enhanced collaboration tools
- Ad-free experience

---

## 3. Functional Requirements

### 3.1 User Authentication  
- Email/password and social login  
- Two-factor authentication and password recovery  

### 3.2 Note Management  
- Upload handwritten pages via camera or gallery  
- Attach and toggle rough work/scratchpad pages  
- Visual timeline with page continuation and drag-drop reorder  
- Auto-create daily note templates with date markers  

### 3.3 AI Integration (Google Gemini AI)  
- Handwriting-to-text conversion with high accuracy  
- Summarization preview and editable flashcards/quizzes  
- Auto-tagging and concept map creation  
- User-supplied and encrypted Gemini API keys
- API credit monitoring dashboard showing usage statistics
- Alert system when API credits running low (quota exceeded errors detected)
- Error handling and user guidance when API quota exceeded
- Usage statistics per user (tokens used, estimated costs, success rates)  

### 3.4 Collaboration  
- Real-time multi-user editing and presence avatars  
- Dedicated chat on notes and notebooks  
- Role-based access: view/comment/edit  
- Notifications for comments and chat activity  

### 3.5 Productivity Tools  
- Assignment/task tracking dashboard  
- Pomodoro timer and study streak analytics  
- LaTeX editor for math equations  
- Citation and reference manager  

### 3.6 Export & Import  
- Batch PDF export of notes/folders including images and annotations  
- Import PDFs and slides for annotation  

### 3.7 Offline Support  
- Local caching with automatic sync when online  
- Conflict resolution UI for multi-device edits  

### 3.8 Security  
- Encrypted Gemini API keys stored securely  
- Password protection per note or folder  
- Data export and recovery options  

### 3.9 Quota Management  
- Track monthly page uploads per user
- Enforce 100-page limit for free tier
- Display usage dashboard (pages used, storage used, API calls made)
- Alert users at 80% and 100% quota usage
- Graceful degradation when quotas exceeded (read-only mode for notes)
- Reset quotas monthly on the 1st of each month
- Premium tier users have unlimited pages

---

## 4. Additional Features (UI/UX Enhancements)

### 4.1 Rough Work Pages  
- Attach rough work pages linked visually to main notes  
- Toggle rough work view without clutter  

### 4.2 Timeline Continuity  
- Visual timeline with continuation arrows  
- Drag-and-drop page reordering  

### 4.3 AI Utilities Panel  
- Side panel for handwriting conversion status, summary edits, tags, and revision tips  

### 4.4 Collaboration Interface  
- Real-time avatars and typing indicators  
- Comment threads on specific note sections  
- Sharing and permissions modal  
- Notification badges for activity  

### 4.5 Sync & Offline Mode  
- Sync status indicators and offline banners  
- Manual upload button and conflict resolution dialogs  

### 4.6 PDF Export UI  
- Multi-select export UI with progress modal and customizable settings  

### 4.7 Mobile-Specific UI  
- Pinch-to-zoom controls on notes  
- Voice memo recording and playback  
- Quick shortcuts for new note pages and rough work  

### 4.8 Security UI  
- Two-factor authentication setup wizard  
- Password protection toggle UI  
- Encrypted key management dashboard  

### 4.9 Quota Management Interface  
- Usage dashboard showing current month consumption
- Progress bars for pages, storage, API calls
- Upgrade prompts when approaching limits (80%, 100%)
- Settings page to manage API keys with credit status display
- Alert banners when quotas exceeded
- Monthly quota reset notification
- Tier badge display (Free/Premium)

---

## 5. Non-Functional Requirements

- Flutter for cross-platform performance (iOS, Android, Web)  
- Scalable backend with low latency  
- Accessibility compliance (WCAG), GDPR aligned  
- Minimalistic, responsive UI with dark/light mode  
- Secure integration with Google Gemini AI
- Cost-efficient architecture using Supabase free tier (500MB DB, 1GB storage, 2GB bandwidth initially)
- Automated quota tracking and enforcement
- Efficient image compression to reduce storage costs  

---

## 6. UI/UX Design Specifications

### 6.1 Core Screens  
- Timeline with dates and visual continuity  
- Note pages with rough work toggle and AI utilities panel  
- Collaboration chat overlay with real-time indicators  
- Sync/offline mode UI elements  
- API key input with encryption feedback  

### 6.2 Interaction Patterns  
- Drag-and-drop page reordering  
- Pinch-to-zoom and swipe navigation  
- Contextual AI suggestions and summary edits  
- Notification badges and modal dialogs  

---

## 7. System Architecture & Technologies

| Layer        | Technology                          |
|--------------|-----------------------------------|
| Frontend     | Flutter/Dart                      |
| Backend      | Supabase with PostgreSQL          |
| AI Services  | Google Gemini API (encrypted keys)|
| Storage      | Cloud storage with offline sync   |
| Authentication | Supabase Auth, Two-factor auth  |

---

## 8. User Stories & Acceptance Criteria

- Users upload handwritten notes in timeline sequence & toggle rough work pages  
- AI generates summaries & flashcards within seconds  
- Collaborators edit and chat in real-time with presence indicators  
- Offline edits sync seamlessly with conflict resolution  
- Secure, encrypted API key management per user  

---

## 9. Constraints & Assumptions

- Valid Google Gemini API key from users mandatory for AI  
- Internet required for collaboration & AI; offline mode has limited features  
- Compliance with data privacy and security standards  

---

*This SRS guides the development of MyCloudBook ensuring all features and UI/UX elements meet user needs in a secure, scalable, and user-friendly Flutter-based app integrated with Google Gemini AI.*

