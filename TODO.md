# Web Video & Image Fixes - Task List

## Problem
Flutter web app has two bugs:
1. **Videos**: `OptimizedVideoPlayer` uses `better_player_enhanced` which has NO web support → `MissingPluginException`.
2. **Images/thumbnails**: CloudFront not returning CORS headers → blocked on web.

## Steps

### Step 1: Switch web video playback to CustomVideoPlayer  ✅
- [x] `professional_lesson_screen.dart` — use `CustomVideoPlayer` on web
- [x] `downloads_section.dart` — use `CustomVideoPlayer` on web
- [x] `downloads_screen.dart` — use `CustomVideoPlayer` on web

### Step 2: Backend media proxy for CORS (images)
- [x] Create `backend/src/routes/media.routes.js` with `GET /api/media/proxy?url=...`
- [x] Register media routes in `server.js`

### Step 3: Route web images/videos through proxy
- [x] Create `frontend/lib/utils/media_proxy.dart` — wraps CloudFront/S3 URLs via backend proxy on web only
- [x] Update `network_image_widget.dart` to proxy CloudFront URLs on web
- [x] Proxy all CDN `Image.network`/`NetworkImage` calls (admin_dashboard, course_analytics, admin_teachers, library, ai_chat_message, multiple_choice/essay/true_false/drag_drop question widgets, main_layout, responsive_navigation_drawer, admin_books)
- [x] Proxy web video URLs in `custom_video_player.dart` (`_getOptimizedUrl` → `mediaProxyUrl` on `kIsWeb`)
- [x] Fix all `mediaProxyUrl` missing-import build errors

### Step 4: Documentation
- [x] Add `WEB_MEDIA_CORS_FIX.md` with CloudFront console CORS setup instructions
