Software Requirements Specification (SRS)
MyCloudBook - AI-Powered Digital Notebook Platform
1. Introduction
1.1 Purpose
This document details requirements for MyCloudBook, a cross-platform Flutter app that digitizes, organizes, and enhances handwritten notes using Google Gemini AI. It targets students and professionals, allowing handwriting-to-text conversion, AI summarization, collaborative editing, and offline functionality.

1.2 Scope
MyCloudBook supports image uploads of handwritten notes forming a timeline, rough work attachments, AI-powered study aids, real-time collaboration, secure API key storage, and seamless offline-online sync, deployed on iOS, Android, and Web with Flutter.

1.3 Intended Audience
App developers, UI/UX designers, AI engineers, project managers, and stakeholders.

2. General Description
2.1 Product Perspective
Combines Flutter frontend, Supabase backend, and Google Gemini AI via user API keys (encrypted) to offer a unified study platform.

2.2 Product Features Summary
Daily-page uploads in a continuous timeline flow

Rough work linked pages toggle

Gemini AI handwriting recognition, summarization, and flashcard generation

Real-time collaboration and chat with role-based permissions

Offline mode with sync and conflict resolution

PDF batch export with customizable settings

Assignment tracking, Pomodoro timer, LaTeX math editor

Encrypted Gemini API key storage, two-factor auth

3. Functional Requirements
3.1 User Authentication
Email/password and social login

Two-factor authentication and password recovery

3.2 Note Management
Handwritten page uploads (camera/gallery)

Link and toggle rough work/scratchpad pages

Timeline with page continuation and drag-drop reorder

Auto-day template with date markers

3.3 AI Integration (Google Gemini AI)
Handwriting-to-text conversion with high accuracy

AI summarization, editable flashcards, quizzes

Smart auto-tagging and concept map linking

User-supplied and encrypted Gemini API key storage

3.4 Collaboration
Real-time multi-user editing and presence indicators

Dedicated chat on notes and notebooks

Role-based access: view/comment/edit

Notification for comments and chat activity

3.5 Productivity Tools
Assignment/task tracker dashboard

Pomodoro timer and study streak analytics

LaTeX mathematical equations editor

Citation and reference management

3.6 Export & Import
Batch PDF export of notes/folders (with images and annotations)

Import PDFs/slides for annotation

3.7 Offline Support
Local caching with sync on reconnect

Conflict resolution UI for multi-device edits

3.8 Security
Encrypted Gemini API keys storage

Password protection per note/folder

Comprehensive data export and recovery

4. Missing Features Added
4.1 Rough Work Pages UI
Attachment interface between core notes and rough work pages

Toggle and view separation with visual linkage

4.2 Timeline Continuity UI
Visual continuous timeline with arrows

Drag-and-drop page rearrangement

4.3 AI Utilities Panel UI
Side panel for conversion status, summarization edits, smart tags, and revision tips

4.4 Collaboration UI
Real-time collaborator avatars and typing indicators

Comment thread overlays and notification badges

Sharing modal with role-based permission settings

4.5 Sync & Offline Mode Indicators
Visual sync status and offline banners

Manual upload buttons

Conflict resolution dialogues

4.6 PDF Export Flow
Multi-select note/folder export UI

Export progress modal with customizable settings

4.7 Mobile-Specific UI
Pinch-to-zoom gestures for note pages

Voice memos recording/playback controls

Quick action shortcuts for note/rough work add

4.8 Security & Privacy UI
Two-factor auth setup wizard

Password protection toggles

Encrypted key management and data recovery dashboards

5. Non-Functional Requirements
Flutter for iOS, Android, and Web cross-platform support

Scalable backend with Supabase real-time sync

Accessibility compliance (WCAG), GDPR, and privacy regulations

Responsive, minimalistic UI with dark/light mode

Low latency AI processing with Google Gemini integration

6. UI/UX Design Specifications
6.1 Core Screens
Timeline with date headers and visual continuity

Note page with rough work toggle and AI utilities panel

Collaboration chat overlay and real-time user indicators

Sync and offline mode banners

API key entry modal with encryption feedback

6.2 Interaction Patterns
Drag-and-drop reordering

Pinch to zoom and swipe page navigation

Contextual AI suggestions and editable summaries

Notification badges and modal dialogues

7. System Architecture & Technologies
Frontend: Flutter/Dart cross-platform UI

Backend: Supabase with PostgreSQL, authentication, and real-time updates

AI Services: Google Gemini API with encrypted per-user keys

Storage: Cloud-based with offline sync and conflict management

8. User Stories & Acceptance Criteria
Users upload handwritten notes in timeline order and toggle rough work pages

AI generates summaries and flashcards within seconds

Collaborators edit notes in real-time with presence indicators and chat

Offline edits sync automatically with conflict resolution support

Secure API keys encrypt in the database with exclusive user access

9. Assumptions & Constraints
Users provide a valid Google Gemini API key for AI features

Internet needed for collaboration and AI features; offline mode supports limited local operation

Data privacy and security protections align with best industry standards

