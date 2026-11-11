# Crappy Turd: Google Play submission guide

Work top to bottom. Each section matches a Play Console screen, and the
answers are what's true for this app. The release build requests no
permissions at all: no internet and no advertising ID.

## 0. Account setup (Dashboard)

New personal accounts have to finish these before publishing:

- **Verify your identity.** Google asks for a government ID. You have to do this yourself.
- **Verify your contact phone number and email.**
- **Verify a physical Android device.** Install the Play Console app on an
  Android phone and sign in with the developer account.

Some of these can take a few days to clear. You can keep setting up the
app in the meantime.

## 1. Create app

**All apps → Create app**

| Field | Answer |
| --- | --- |
| App name | `Crappy Turd` |
| Default language | English (United States) |
| App or game | **Game** |
| Free or paid | **Free** (you can't change a free app to paid later) |
| Declarations | Tick both: Developer Program Policies and US export laws |

## 2. Store listing

**Grow users → Store presence → Main store listing**

**App name** (30 max)

```
Crappy Turd
```

**Short description** (80 max)

```
Flap a cute little turd through the pipes. How far can you go?
```

**Full description** (4000 max)

```
Tap to flap. Don't hit the pipes. That's it, and that's the problem.

Crappy Turd is a one-tap arcade game starring a cheerful little turd with big dreams and questionable aerodynamics. Guide it through an endless run of pipes, rack up points, and chase your best score.

• One-tap controls: easy to learn, hard to put down
• Bright, cheerful art with a looping day/night sky, twinkling stars and the occasional shooting star
• Squishy, sparkly flaps, satisfying sound effects, and a mute button for stealth play
• Haptic feedback when you crash
• Your high score is saved on your device

No ads. No in-app purchases. No accounts. No data collection. The game doesn't even use the internet.

How far can you flush it?
```

**Graphics.** Regenerate these with `tool/generate_screenshots.dart` if they're missing:

| Slot | File |
| --- | --- |
| App icon (512×512) | `build/screenshots/icon_512.png` |
| Feature graphic (1024×500) | `build/screenshots/feature_graphic.png` |
| Phone screenshots (min 2) | `build/screenshots/title.png`, `build/screenshots/gameplay.png` |

Skip the tablet and Chromebook screenshot slots. They're optional.

**Store settings** (**Store presence → Store settings**)

- App category: **Game → Arcade**
- Contact email: required, and shown publicly on the listing
- Website and phone: optional

## 3. App content

**Policy and programs → App content.** Each item is its own form.

| Item | Answer |
| --- | --- |
| Privacy policy | `https://github.com/cookiesncache/crappy_turd/blob/main/store/privacy-policy.md` |
| App access | **All functionality is available without special access** |
| Ads | **No, my app does not contain ads** |
| Content rating | See below |
| Target audience | **13–15, 16–17, 18+** (see note) |
| Data safety | See below |
| Advertising ID | **No** (the app doesn't use it, and its manifest has no AD_ID permission) |
| Government apps | **No** |
| Financial features | **My app doesn't provide any financial features** |
| Health | **No** health features |
| News app | **No** |

**Content rating questionnaire (IARC).** Category: **Game**. Answer "No" to
violence, fear, sexuality, gambling, drugs, alcohol and tobacco, and to
user interaction, sharing location or personal info, and digital purchases.
The only "Yes" is the potty humour: if a question asks about crude or toilet
humour, answer Yes. Expect a low rating such as Everyone or PEGI 3–7.

**Target audience note.** Picking any age group under 13 brings in Google's
Families policy and extra forms. The app has no ads and collects nothing, so
it would pass, but 13+ keeps setup simpler. If Google asks whether the app
could unintentionally appeal to children, answer honestly. A cartoon turd
with a smiley face arguably does.

**Data safety form**

- Does your app collect or share any of the required user data types? **No**
- That answer skips the rest of the form. The high score is stored only on
  the device and never sent anywhere, which doesn't count as "collection".

## 4. Closed test (required before production)

**Test and release → Testing → Closed testing**

1. Use the default track ("Closed testing - Alpha") or create one.
2. **Countries/regions:** add every country your testers are in, or all of them.
3. **Testers:** create an email list with at least 12 people's Google
   account emails (Gmail or any Google account), and set a feedback email or URL.
4. **Create new release:**
   - On the first release, accept **Play App Signing** (Google holds the app
     signing key, and your upload keystore stays the upload key).
   - Upload `build/app/outputs/bundle/release/app-release.aab`.
   - Release name: leave the default (`1 (1.0.0)`).
   - Release notes:
     ```
     <en-US>
     First test build of Crappy Turd. Play a few rounds and let me know if anything feels off.
     </en-US>
     ```
5. **Review release → Start rollout to Closed testing.** Google reviews it,
   which can take hours to a few days.
6. Once it's approved, copy the **opt-in link** from the track's Testers tab
   and send it to the testers. Each one opens it, taps "Become a tester",
   then installs from Play.
7. Keep **12 or more testers opted in for 14 days in a row**. Ask them to
   actually play now and then; Google looks at engagement.
8. After 14 days, the Dashboard offers **Apply for production access**,
   which is a short questionnaire about the test. Once approved, promote the
   release to Production.

Each later upload needs a higher build number. Bump `version:` in
`pubspec.yaml` (for example `1.0.0+2`), then rerun `flutter build appbundle`.
