# AgriBrain 360

## Hybrid Offline-First AI Farm Intelligence Platform

This document is a complete end-to-end blueprint for the hackathon project:

**AgriBrain 360 - Hybrid Offline-First AI Farm Intelligence Platform**

It is designed for:
- Rural farmers with weak or unstable internet
- Low-end Android phones with around 2GB RAM
- Practical hackathon implementation
- Real-world scalability after the hackathon

---

## 1. Core App Features (User Side)

### A. User Onboarding and Profile
- Language selection at first launch
- Multi-language UI for regional accessibility
- Farmer profile with name, phone, email, preferred language, and region
- Offline-first login/session support
- Profile persistence after logout/login

### B. Offline-First Experience
- Core app works even with poor or no internet
- On-device AI inference for key modules
- Local history storage for all scans and actions
- Automatic sync when internet returns
- Cached translations, local assets, and offline service data

### C. Smart Dashboard
- Personalized welcome and farm summary
- Farm Health Index snapshot
- Recent activity and scan history
- Quick access to all modules
- Real-time weather card when internet is available
- Offline status banner when device is disconnected

### D. Scan History and Memory
- User-wise history of crop, livestock, residue, and other scans
- Synced history restored after re-login
- Recent activity cards on dashboard
- Time-based history sorting
- Filter by module

### E. Notifications and Alerts
- Scan completion alerts
- Sync pending alerts
- Maintenance reminders
- Weather/risk alerts
- Farm health trend reminders

### F. Voice and Accessibility Features
- Voice input for low-literacy users
- Whisper/cloud fallback voice transcription when online
- Simple visual cards and icons
- Large touch targets for field use
- Multi-language result display

### G. Rural Usability Features
- Fast load time
- Lightweight screens
- Minimal text-first layouts for low-end devices
- Works with intermittent internet
- Low battery and low memory friendly design

### H. Smart Input Validation System
- Validates uploaded/captured images before AI prediction
- Checks whether the image matches supported disease-input categories
- Prevents invalid crop or livestock predictions
- Prompts user to recapture when the image is not suitable
- Reduces false predictions and improves trust in AI output

**User message:**
`Please recapture the image. This does not match a detectable disease input.`

---

## 2. Admin Panel Features

### A. User and Farmer Management
- View registered users
- View active users and offline/online usage trends
- Filter users by district, language, and module usage
- Disable abusive or fake accounts

### B. AI Monitoring
- Monitor model usage by module
- Track success/failure rates of AI predictions
- View confidence distribution and edge-case failures
- Detect modules needing retraining

### C. Content and Translation Management
- Manage multi-language text content
- Update advisory messages
- Add region-specific farming tips
- Manage crop disease descriptions, treatment text, and guidance content

### D. Service Network Management
- Add/edit nearby vets, dealers, mandis, repair centers
- Verify service providers
- Rank featured providers
- Manage sponsored listings

### E. Weather and Advisory Operations
- Push weather alerts by geography
- Push disease outbreak advisories by crop region
- Push seasonal recommendations

### F. Analytics and Reports
- DAU/WAU/MAU metrics
- Most-used modules
- Sync backlog and offline usage rate
- Revenue dashboards
- District-level farmer issue heatmaps

### G. System Operations
- View API health
- Sync queue monitoring
- Cloud storage usage monitoring
- Model version rollout management
- Audit log for admin actions

---

## 3. AI/ML Features

The AI layer should be hybrid:
- **Offline models** for core inference on device
- **Cloud AI** for richer analysis, LLM advice, retraining, and aggregation

### A. Crop Disease Detection Model
- Image classification model
- Detects plant disease from leaf image
- Gives disease label, severity estimate, and treatment hints
- Offline TFLite model for fast device inference
- Cloud model can improve confidence and advisory detail

### B. Crop Detection / Crop Type Identification
- Image-based crop identification
- Helps farmers identify crop type from plant photo
- Used as a helper signal for disease and fertilizer modules

### C. Crop Recommendation Model
- Tabular ML model
- Inputs soil and weather parameters
- Predicts best crop for the land
- Offline recommendation supported through TFLite

### D. Fertilizer Recommendation Model
- Tabular model
- Uses crop type, soil type, NPK, moisture, humidity, temperature
- Suggests the most suitable fertilizer
- Offline-first inference

### E. Livestock Health Model
- Symptom-based and image-assisted diagnosis
- Predicts disease/risk level for cattle, goats, poultry, etc.
- Gives first-aid guidance and advisory
- Can combine rules + lightweight ML for hackathon MVP

### F. Smart Input Validation Model
- Lightweight image screening model or rule-based classifier
- Runs before the main disease model
- Confirms whether the image belongs to supported crop leaf or livestock disease patterns
- Rejects invalid images such as random objects, human faces, sky, soil-only images, blurred frames, or unrelated scenes
- Prevents garbage-in, garbage-out predictions

### G. Machinery Intelligence
- Rule engine for machine recommendation
- Maintenance risk scoring based on last service date and usage hours
- Future AR overlay / step guide system
- Rental recommendation based on crop, land, and location

### H. Crop Residue Value Model
- Converts residue type and moisture into best income option
- Suggests compost, fodder, briquettes, sale, or reuse
- Estimates projected earnings
- Can begin with rule-based + simple ML scoring

### I. Farm Health Index Model
- Multi-factor farm score system
- Combines crop, soil, water, livestock, and machinery health
- Produces overall farm readiness score
- Can evolve into predictive risk model later

### J. AI Advisory Layer
- LLM-generated practical advice in simple language
- Used when internet is available
- Converts raw AI outputs into farmer-friendly action plans

---

## 4. Module Breakdown

## 4.1 Crop Disease Detection

### Input
- Leaf image
- Optional crop type
- Optional farm notes by text or voice
- Optional area size

### Processing
- Smart input validation checks whether the image is a valid detectable crop disease input
- On-device image preprocessing
- TFLite disease classification
- Severity estimation
- Optional cloud verification when online
- Treatment and ROI advisory generation

### Output
- Disease name
- Confidence score
- Severity level
- Symptoms summary
- Treatment plan
- Estimated treatment cost vs loss
- Scan saved to history
- If invalid input:
  - prediction is blocked
  - user sees: `Please recapture the image. This does not match a detectable disease input.`

### Tech Used
- Flutter
- TFLite
- Image picker / camera
- FastAPI
- Optional cloud advisory service

---

## 4.2 Livestock Health Monitoring

### Input
- Animal type
- Symptoms by text or voice
- Optional animal image

### Processing
- Smart input validation checks whether the image belongs to a supported livestock disease input
- Symptom parsing
- Rule-based fallback for offline diagnosis
- Image classification if animal photo exists
- Risk scoring
- Online advisory enrichment

### Output
- Suspected disease
- Risk level
- First-aid protocol
- Treatment/advisory text
- Nearest vet recommendation
- History entry
- If invalid image:
  - diagnosis is not triggered from image
  - user sees: `Please recapture the image. This does not match a detectable disease input.`

### Tech Used
- Flutter
- Voice input
- TFLite or lightweight classifier
- FastAPI
- Geolocation for nearest services

---

## 4.3 Machinery Repair (AR or Guide)

### Input
- Machine type
- Crop type
- Land size
- Last service date
- Operating hours
- Location

### Processing
- Rule-based machine recommendation
- Maintenance scoring
- Cost estimation
- Nearby rental lookup
- Guide/repair workflow
- Future AR overlay for part identification

### Output
- Recommended machine
- Maintenance status: Good / Due Soon / Urgent
- Estimated rental cost
- Fuel/operator cost estimate
- Nearby rental providers
- Repair guide steps

### Tech Used
- Flutter
- Rules engine
- Local service data + API sync
- Geolocation
- Future ARCore / guided overlay support

---

## 4.4 Crop Residue Income System

### Input
- Residue image
- Residue type
- Moisture level
- Optional voice notes

### Processing
- Residue classification or rule-based mapping
- Moisture-based quantity adjustment
- Value scoring of different reuse options
- Option ranking by income potential

### Output
- Best residue utilization option
- Estimated quantity
- Projected earnings
- Other alternate options
- History entry

### Tech Used
- Flutter
- Camera
- Lightweight rules / ML scoring
- FastAPI for online enrichment

---

## 4.5 Hyperlocal Service Finder

### Input
- GPS location or manual city input
- Category filter
- Search query

### Processing
- Local cached provider search
- Distance sorting
- Online refresh when connected
- Category filtering

### Output
- Nearby vets
- Input dealers
- Repair centers
- Mandis
- Distance and rating
- Contact details

### Tech Used
- Flutter
- Geolocator
- Local JSON cache
- FastAPI service API

---

## 4.6 Farm Health Index System

### Input
- Crop score
- Soil score
- Water score
- Livestock score
- Machinery score
- Historical trend data

### Processing
- Weighted scoring
- Overall farm score computation
- Trend comparison
- Risk labeling

### Output
- Farm Health Index score
- Category-wise scores
- Critical area detection
- Improvement suggestions
- Dashboard summary

### Tech Used
- Flutter
- Local storage
- FastAPI
- Simple analytics engine

---

## 5. User Flow (Step-by-Step)

### Step 1: First Launch
- User opens app
- Selects preferred language
- Sees intro and login/signup

### Step 2: Authentication
- User signs up or logs in
- Profile is stored locally
- If internet exists, profile syncs to cloud
- If offline, app still starts in local mode

### Step 3: Dashboard
- User lands on dashboard
- Sees farm health, recent scans, quick actions, and weather if online

### Step 4: Choose a Module
- Farmer selects crop, livestock, machinery, residue, services, or health module

### Step 5: Provide Input
- Photo, text, voice, or manual farm values are entered

### Step 6: Offline AI Processing
- Device runs local model or rules engine
- Result is shown instantly without requiring internet

### Step 7: Save and Sync
- Result is saved locally
- If internet is available, cloud sync runs
- If offline, result is queued for later sync

### Step 8: Actionable Outcome
- Farmer receives practical output:
  - disease diagnosis
  - treatment plan
  - machine recommendation
  - service provider
  - residue income path
  - farm score

### Step 9: Revisit Later
- Farmer can view history anytime
- On re-login, same history is restored to that account

---

## 6. Backend Architecture

### A. High-Level Architecture
- **Mobile App**: Flutter Android app
- **Offline Layer**: Local Hive/SQLite style storage
- **Backend API**: FastAPI
- **Cloud DB**: PostgreSQL / Supabase
- **Auth**: Supabase Auth
- **AI Services**: On-device TFLite + cloud advisory APIs

### B. Database Design

#### Local Database
Use lightweight local storage for:
- user session
- scan history
- sync queue
- latest farm health score
- cached service lists
- cached translations/config

Recommended:
- Hive for fast local object storage
- Optional SQLite if relational complexity grows

#### Cloud Database
Use PostgreSQL/Supabase for:
- user profiles
- synced scan history
- module records
- notifications
- admin content
- service provider directory
- analytics tables

### C. APIs

Recommended API groups:
- `/auth/*`
- `/crop/*`
- `/livestock/*`
- `/fertilizer/*`
- `/machinery/*`
- `/residue/*`
- `/services/*`
- `/health/*`
- `/sync/*`
- `/admin/*`

### D. Offline Storage Strategy
- Every important action is saved locally first
- UI always reads from local store first
- Network layer only enriches or syncs
- Last successful cloud data is cached

### E. Sync Mechanism

#### Sync Principles
- Local-first write
- Background retry
- User-wise data ownership
- Conflict-safe upsert

#### Sync Flow
1. Farmer creates scan offline
2. Record saved locally
3. Record added to sync queue
4. Internet returns
5. Background sync sends queued records
6. Server stores account-linked history
7. App restores synced history on login/startup

### F. Production Readiness
- Token-based auth
- Background retry queue
- Structured logging
- Error-handling middleware
- Timeouts and graceful fallbacks
- Rate limiting for public APIs
- Versioned APIs

---

## 7. Frontend Features

### A. UI Screens List
- Splash screen
- Language picker
- Login / signup
- Dashboard
- Notifications
- Profile
- Scan history
- Crop module selection
- Crop disease scan
- Crop result screen
- Crop recommendation screen
- Fertilizer recommendation screen
- Livestock input screen
- Livestock result screen
- Machinery module screens
- Residue analysis screen
- Residue income result screen
- Nearby services screen
- Service contact/detail screen
- Farm health input screen
- Farm health result screen
- Forgot password / OTP / reset flow

### B. Navigation Flow
- Splash -> Language -> Login -> Dashboard
- Dashboard -> Any module
- Module -> Result -> Save history -> Back to dashboard
- Dashboard/Profile -> History
- Dashboard -> Notifications

### C. Important UI Components
- Language selector
- Quick action cards
- Module cards
- Weather card
- FHI gauge card
- History list tiles
- Offline banner
- Voice input button
- Loading overlay
- Sync status indicators
- Reusable action buttons

### D. UI Principles for Rural Users
- Large buttons
- Few steps per task
- Card-based navigation
- Strong visual hierarchy
- Minimal typing required
- Voice-assisted entry

---

## 8. Unique Features (Innovation)

These are strong hackathon differentiators.

### A. Hybrid Offline-First AI
- Core diagnosis works without internet
- Cloud improves results when internet is available
- This directly solves rural connectivity pain

### B. Unified Farm Intelligence App
- Most apps solve one farm problem
- AgriBrain 360 unifies crop, livestock, machinery, residue, services, and health index

### C. Farm Health Index
- A single overall score for farm wellness
- Judges will like this because it connects all modules into one intelligence layer

### D. Residue Income Engine
- Converts waste into monetizable opportunities
- Strong sustainability + income impact story

### E. Hyperlocal Rural Utility Layer
- Nearby vet, mandi, dealer, repair center
- Bridges AI insight to real-world action

### F. Multi-Language + Voice for Inclusion
- Designed for low literacy and local language use
- Strong social impact angle

### G. Account-Linked Sync with Offline Operation
- User history remains after logout/relogin
- Works even when device is temporarily offline

### H. Weather + Risk-Aware Advisory
- Combines real-time conditions with AI outcomes
- Makes advice more actionable

---

## 9. Monetization Features

### A. B2C Freemium
- Free basic scans
- Premium unlimited scans
- Premium advanced advisory
- Premium farm trend analytics

### B. B2B for Agri Input Companies
- Sponsored fertilizer recommendations
- Verified input dealer promotion
- Regional campaign insights

### C. Service Marketplace Revenue
- Lead fees from vets, repair shops, dealers, rental owners
- Featured service listing subscription

### D. Mandi and Buyer Partnerships
- Crop residue buyer marketplace commissions
- B2B residue aggregation partnerships

### E. Cooperative / FPO / NGO Dashboard
- Subscription for farmer groups
- Batch monitoring and advisory reporting

### F. Agri-Insurance / Lending Partnerships
- Farm Health Index as partner signal
- Credit risk or advisory integration opportunities

---

## 10. Future Scalability

### A. AI Upgrades
- Better disease segmentation
- Pest detection
- Yield prediction
- Soil image analysis
- Satellite + weather fusion

### B. Government Integration
- Scheme eligibility checker
- Subsidy recommendation
- Crop insurance workflows
- Soil health card integration

### C. Marketplace Expansion
- Farm produce marketplace
- Rental marketplace
- Vet teleconsultation
- Input ordering

### D. Community Features
- Farmer discussion forum
- Local crop issue reporting
- Community disease outbreak map

### E. Advanced Advisory
- Personalized seasonal calendar
- Proactive irrigation alerts
- Pest outbreak warnings
- Disease spread prediction by district

### F. Enterprise Scale
- Multi-tenant admin panel
- District and state deployment
- Analytics warehouse
- Model monitoring pipelines
- Feature flags for staged rollout

---

## MVP vs Advanced Plan

## MVP for Hackathon
- Language selection
- Login/signup
- Offline-first local storage
- Crop disease scan
- Livestock diagnosis
- Machinery recommendation + maintenance
- Residue income estimation
- Service finder
- Farm Health Index
- Local history + sync queue
- Real-time weather on dashboard
- Smart input validation before crop/livestock image prediction

## Advanced but Optional for Hackathon
- AR machinery repair guidance
- LLM advisory in all modules
- District-level admin analytics
- Push weather alerts
- Sponsored listings
- Tele-vet integration
- Community reporting
- Separate dedicated authenticity model trained for unsupported-image rejection

---

## Integration Story Across Modules

This is one of the strongest project angles.

- Crop disease results affect farm health score
- Livestock diagnosis affects livestock health score
- Machinery maintenance affects machinery score
- Residue income affects waste-to-income strategy and sustainability story
- Nearby services convert AI recommendation into action
- Weather improves advisories and planning
- History ties everything to one farmer account
- Smart input validation improves model reliability before results enter history and advisory flows

---

## Smart Input Validation System Design

This feature acts as a **pre-check layer** before the main AI model runs.

### Goal
- Stop invalid images from reaching the disease detection pipeline
- Improve trust, precision, and user experience
- Reduce false positives caused by unrelated or low-quality images

### Where It Works
- Crop Disease Detection
- Livestock Health Monitoring

### Validation Logic
1. User captures or uploads image
2. App runs a lightweight validation model or screening rule
3. System checks whether the image looks like:
   - a supported crop leaf disease image, or
   - a supported livestock disease/condition image
4. If valid:
   - continue to main AI prediction
5. If invalid:
   - stop prediction
   - show message:
     `Please recapture the image. This does not match a detectable disease input.`

### What Should Be Rejected
- Random objects
- Hands or faces
- Blank or dark images
- Very blurred images
- Soil-only or sky-only images
- Non-disease crop scenes when disease detection is expected
- Unrelated animal images with no visible disease evidence

### Implementation Options

#### MVP Option
- Simple lightweight binary classifier:
  - valid disease input
  - invalid / unsupported image
- Can also combine image-quality checks:
  - blur detection
  - minimum brightness
  - object coverage threshold

#### Advanced Option
- Multi-stage validator:
  - image quality check
  - domain classifier:
    - crop leaf
    - livestock
    - unsupported
  - module-specific disease-input validator

### Tech Used
- TFLite lightweight validation model
- Optional OpenCV-style blur/brightness checks
- Flutter pre-inference validation step
- Shared error messaging layer

### Why This Matters for Judges
- Shows production thinking
- Improves AI reliability
- Prevents misleading outputs
- Demonstrates responsible AI design, not just raw prediction

This turns the app from a set of tools into a **full farm operating intelligence system**.

---

## Suggested Tech Stack

### Mobile
- Flutter
- Hive for local storage
- TFLite for on-device inference
- Geolocator
- Shared Preferences
- Camera / image picker

### Backend
- FastAPI
- PostgreSQL / Supabase
- Supabase Auth
- REST APIs
- Background sync jobs

### AI/ML
- TensorFlow / Keras
- TFLite export
- Lightweight tabular models
- Rule engine where ML is unnecessary
- Optional LLM advisory layer

### Admin
- React / Next.js or Flutter Web
- Chart dashboards
- CRUD panels

---

## Data Storage Mapping

This section explains exactly where each type of data is stored.

| Data Type | Stored In Hive (Local Device) | Stored In PostgreSQL / Supabase (Cloud) | Notes |
|---|---|---|---|
| Language preference | Yes | Optional | Needed for instant app startup and offline continuity |
| Logged-in user session | Yes | No | Local session state for offline-first experience |
| Access token | Yes | No | Stored on device for authenticated API use |
| Farmer profile | Yes | Yes | Local copy for quick access, cloud copy as source of truth |
| Scan history | Yes | Yes | Saved locally first, then synced to cloud |
| Recent activity | Yes | Derived from cloud history | Dashboard reads local first |
| Sync queue | Yes | Optional server logs only | Queue is device-local and retries when internet returns |
| Crop disease scan results | Yes | Yes | Stored for history, analytics, and restore after login |
| Crop recommendation results | Yes | Yes | Stored locally first and synced later |
| Fertilizer recommendation context/results | Yes | Optional / recommended Yes | Useful for future analytics and personalized advice |
| Livestock diagnosis results | Yes | Yes | Synced per user for account-based history |
| Machinery recommendation / maintenance results | Yes | Recommended Yes | Important for continuity and reminders |
| Residue analysis results | Yes | Yes | Needed for restore and trend analysis |
| Farm Health Index latest score | Yes | Yes | Local latest snapshot plus cloud history/trends |
| Notifications metadata | Yes | Optional | Read/dismiss state is local, push events can exist in cloud later |
| Nearby services offline cache | Yes | No | Bundled or cached locally for use without internet |
| Live weather data | Temporary only | No | Fetched live, usually not worth long-term DB storage for MVP |
| Admin-managed service providers | No | Yes | Source of truth should be cloud database |
| Translation content | Bundled assets | Optional admin CMS later | Current app uses bundled JSON language files |
| Model metadata / config | Bundled assets | Optional | Usually shipped with app build for offline use |
| Analytics / usage logs | No | Yes | Needed for admin dashboard and monitoring |
| Error logs / audit trails | No | Yes | Backend and admin operations should be logged in cloud |

### What Hive Stores in Your Current App

Based on the current implementation, Hive is used for:
- user profile/session
- scan history
- sync queue
- latest farm health index
- notification read/dismiss metadata

### What PostgreSQL / Supabase Stores in Your Current App

Based on the current backend, PostgreSQL stores:
- profiles
- crop scans
- livestock records
- health index records
- sync-related server records
- password reset OTP records
- unified scan history records

### Simple Architecture Rule

Use this rule while building:

- **Hive = fast local working memory for offline use**
- **PostgreSQL/Supabase = permanent account-linked source of truth**

### Best Practice for Offline-First Sync

For every important farmer action:
1. Save to Hive first
2. Show result immediately
3. Add to local sync queue
4. Sync to PostgreSQL when internet returns
5. Restore cloud history back to Hive on login/startup

This is the correct model for your project because it gives:
- offline usability
- low latency on cheap phones
- reliable account-based history
- production scalability

---

## Hackathon Judge Pitch Summary

**AgriBrain 360** is a practical, offline-first AI farming assistant built for rural farmers using low-end Android phones. It combines crop diagnosis, livestock health, machinery support, residue monetization, nearby services, farm health scoring, and real-time weather into one unified platform. The app works offline, syncs automatically later, supports local languages, and turns AI outputs into real-world farmer action.

Why it stands out:
- Solves a real rural problem: unreliable internet
- Integrates multiple farm needs in one app
- Uses hybrid AI: on-device + cloud
- Practical enough for MVP, scalable enough for production
- Strong social impact + monetization story

---

## Final Build Strategy

If the goal is to win the hackathon, present the product in three layers:

### 1. Problem
- Farmers face fragmented tools, weak internet, low language accessibility, and delayed expert access

### 2. Solution
- One offline-first AI app that supports core farm decisions across crop, livestock, machinery, residue, services, and health

### 3. Impact
- Lower crop loss
- Faster decisions
- Better machinery use
- Improved livestock response
- Extra income from residue
- Better access to local services

---

## Recommended Demo Flow for Judges

1. Open app in local language
2. Show offline mode banner
3. Run crop disease detection offline
4. Save result to history
5. Show livestock diagnosis
6. Show machinery recommendation and rental estimate
7. Show residue income output
8. Show nearby services
9. Show Farm Health Index
10. Turn internet on and show weather + sync restore

This demo flow clearly proves:
- real utility
- offline-first design
- module integration
- production thinking
