#!/usr/bin/env bash
# apply-nova-patches.sh — apply all NovaOS patches to their repos in an AOSP/LineageOS tree.
# The patches are embedded in this script, so it is fully self-contained.
#
# Usage:  ./apply-nova-patches.sh [options] [ANDROID_TOP]
#   ANDROID_TOP   root of your source tree (the dir holding frameworks/, packages/, vendor/).
#                 Defaults to $ANDROID_BUILD_TOP, then the current directory.
# Options:
#   -n, --check     dry run: only run `git apply --check`, change nothing
#   -r, --revert    reverse the patches (undo)
#   -c, --commit    git commit after applying (same messages as the README)
#   -p, --push      commit, then push to remote "github" branch lineage-24.0
#   -h, --help      show this help
set -uo pipefail

MODE=apply; COMMIT=0; PUSH=0; TOP=""
REMOTE=github; BRANCH=lineage-24.0

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--check)  MODE=check ;;
    -r|--revert) MODE=revert ;;
    -c|--commit) COMMIT=1 ;;
    -p|--push)   COMMIT=1; PUSH=1 ;;
    -h|--help)   sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)          echo "Unknown option: $1" >&2; exit 2 ;;
    *)           TOP="$1" ;;
  esac
  shift
done
TOP="${TOP:-${ANDROID_BUILD_TOP:-$PWD}}"
TOP="$(cd "$TOP" 2>/dev/null && pwd)" || { echo "Not a directory: $TOP" >&2; exit 2; }

if [ -t 1 ]; then G=$'\e[32m'; R=$'\e[31m'; Y=$'\e[33m'; N=$'\e[0m'; else G=; R=; Y=; N=; fi
ok()   { echo "${G}[ OK ]${N} $*"; }
skip() { echo "${Y}[SKIP]${N} $*"; }
fail() { echo "${R}[FAIL]${N} $*"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Write the embedded patches to $WORK
extract() {
  mkdir -p "$WORK/frameworks_base" "$WORK/Settings" "$WORK/Launcher3"
  cat > "$WORK/frameworks_base/nova-wire-cc.patch" <<'NOVA_PATCH_EOF'
--- a/packages/SystemUI/compose/features/src/com/android/systemui/qs/ui/composable/QuickSettingsContent.kt
+++ b/packages/SystemUI/compose/features/src/com/android/systemui/qs/ui/composable/QuickSettingsContent.kt
@@ -42,6 +42,7 @@
 import com.android.systemui.media.remedia.ui.compose.Media
 import com.android.systemui.media.remedia.ui.compose.MediaPresentationStyle
 import com.android.systemui.qs.composefragment.ui.GridAnchor
+import com.android.systemui.qs.nova.NovaControlCenterDemo
 import com.android.systemui.qs.panels.ui.compose.TileGrid
 import com.android.systemui.qs.shared.ui.QuickSettings.Elements
 import com.android.systemui.qs.ui.viewmodel.QuickSettingsContainerViewModel
@@ -96,9 +97,10 @@
 
                 Box {
                     GridAnchor()
-                    TileGrid(
-                        viewModel.tileGridViewModel,
-                        listening = { listening },
+                    // Nova: Control Center-style layout. Placeholder tiles until the real
+                    // tile composables are wired in. Revert this block to go back to the
+                    // stock grid.
+                    NovaControlCenterDemo(
                         modifier = Modifier.element(Elements.QuickSettingsTiles),
                     )
                 }
NOVA_PATCH_EOF
  cat > "$WORK/Settings/nova-ios-settings.patch" <<'NOVA_PATCH_EOF'
diff --git a/res/drawable/preference_background.xml b/res/drawable/preference_background.xml
index 9a1cc46..1af2836 100644
--- a/res/drawable/preference_background.xml
+++ b/res/drawable/preference_background.xml
@@ -1,18 +1,12 @@
 <?xml version="1.0" encoding="utf-8"?>
-<!-- Copyright (C) 2014 The Android Open Source Project
-
-     Licensed under the Apache License, Version 2.0 (the "License");
-     you may not use this file except in compliance with the License.
-     You may obtain a copy of the License at
-
-          http://www.apache.org/licenses/LICENSE-2.0
-
-     Unless required by applicable law or agreed to in writing, software
-     distributed under the License is distributed on an "AS IS" BASIS,
-     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-     See the License for the specific language governing permissions and
-     limitations under the License.
+<!--
+  Nova: iOS-style rounded card behind every Settings row.
+  Stock is a flat colour:
+      <color android:color="@color/materialColorSurfaceContainer" />
+  Same idea, white in light / #1C1C1E in dark, 10dp corners like iOS.
 -->
-
-<color xmlns:android="http://schemas.android.com/apk/res/android"
-       android:color="@color/materialColorSurfaceContainer" />
+<shape xmlns:android="http://schemas.android.com/apk/res/android"
+    android:shape="rectangle">
+    <solid android:color="@color/nova_card_background" />
+    <corners android:radius="10dp" />
+</shape>
diff --git a/res/drawable/preference_highlight.xml b/res/drawable/preference_highlight.xml
index 105ff18..8a4af5c 100644
--- a/res/drawable/preference_highlight.xml
+++ b/res/drawable/preference_highlight.xml
@@ -1,21 +1,11 @@
 <?xml version="1.0" encoding="utf-8"?>
-<!-- Copyright (C) 2014 The Android Open Source Project
-
-     Licensed under the Apache License, Version 2.0 (the "License");
-     you may not use this file except in compliance with the License.
-     You may obtain a copy of the License at
-
-          http://www.apache.org/licenses/LICENSE-2.0
-
-     Unless required by applicable law or agreed to in writing, software
-     distributed under the License is distributed on an "AS IS" BASIS,
-     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-     See the License for the specific language governing permissions and
-     limitations under the License.
--->
-
+<!-- Nova: press ripple clipped to the 10dp card corners. -->
 <ripple xmlns:android="http://schemas.android.com/apk/res/android"
-    android:color="?android:attr/colorControlHighlight">
-    <item android:id="@android:id/mask"
-          android:drawable="@android:color/white" />
+    android:color="@color/nova_card_background_pressed">
+    <item android:id="@android:id/mask">
+        <shape android:shape="rectangle">
+            <solid android:color="@android:color/white" />
+            <corners android:radius="10dp" />
+        </shape>
+    </item>
 </ripple>
diff --git a/res/values-night/colors.xml b/res/values-night/colors.xml
index 386a763..1327508 100644
--- a/res/values-night/colors.xml
+++ b/res/values-night/colors.xml
@@ -128,5 +128,10 @@
     <color name="setup_compat_footer_primary_button_bg_color">@*android:color/system_primary_dark</color>
     <color name="setup_compat_footer_primary_button_text_color">@*android:color/system_on_primary_dark</color>
 
+
+    <!-- Nova: iOS grouped list look, dark -->
+    <color name="nova_grouped_background">#000000</color>
+    <color name="nova_card_background">#1C1C1E</color>
+    <color name="nova_card_background_pressed">#2C2C2E</color>
 </resources>
 
diff --git a/res/values/colors.xml b/res/values/colors.xml
index 4d076e2..f5b6d95 100644
--- a/res/values/colors.xml
+++ b/res/values/colors.xml
@@ -336,4 +336,9 @@
     <color name="setup_compat_footer_primary_button_bg_color">@*android:color/system_primary_light</color>
     <color name="setup_compat_footer_primary_button_text_color">@*android:color/system_on_primary_light</color>
 
+
+    <!-- Nova: iOS grouped list look -->
+    <color name="nova_grouped_background">#F2F2F7</color>
+    <color name="nova_card_background">#FFFFFF</color>
+    <color name="nova_card_background_pressed">#E5E5EA</color>
 </resources>
diff --git a/res/values/themes.xml b/res/values/themes.xml
index 7422dbc..ca75606 100644
--- a/res/values/themes.xml
+++ b/res/values/themes.xml
@@ -29,6 +29,8 @@
     </style>
 
     <style name="Theme.Settings" parent="Theme.SettingsBase">
+        <!-- Nova: iOS groups list items on a grey page instead of one flat surface -->
+        <item name="android:colorBackground">@color/nova_grouped_background</item>
         <item name="android:clipToPadding">false</item>
         <item name="android:clipChildren">false</item>
         <item name="preferenceTheme">@style/SettingsPreferenceTheme</item>
@@ -204,7 +206,7 @@
         <!-- Homepage should follow device default design, the values is same as device default theme.-->
         <item name="android:navigationBarColor">@android:color/white</item>
         <item name="android:statusBarColor">?attr/colorPrimaryDark</item>
-        <item name="android:colorBackground">@color/settingslib_materialColorSurfaceContainerLow</item>
+        <item name="android:colorBackground">@color/nova_grouped_background</item>
     </style>
 
     <style name="Theme.Settings.Home.NoAnimation">
NOVA_PATCH_EOF
  cat > "$WORK/Launcher3/nova-home-labels.patch" <<'NOVA_PATCH_EOF'
--- a/res/xml/device_profiles.xml
+++ b/res/xml/device_profiles.xml
@@ -111,7 +111,7 @@
             launcher:minWidthDps="275"
             launcher:minHeightDps="420"
             launcher:iconImageSize="60"
-            launcher:iconTextSize="12.0"
+            launcher:iconTextSize="0"
             launcher:allAppsBorderSpace="16"
             launcher:allAppsCellHeight="104"
             launcher:startAlignTaskbar="true"
@@ -123,7 +123,7 @@
             launcher:minWidthDps="255"
             launcher:minHeightDps="450"
             launcher:iconImageSize="60"
-            launcher:iconTextSize="12.0"
+            launcher:iconTextSize="0"
             launcher:allAppsBorderSpace="16"
             launcher:allAppsCellHeight="104"
             launcher:startAlignTaskbar="true"
@@ -135,7 +135,7 @@
             launcher:minWidthDps="296"
             launcher:minHeightDps="491.33"
             launcher:iconImageSize="60"
-            launcher:iconTextSize="12.0"
+            launcher:iconTextSize="0"
             launcher:allAppsBorderSpace="16"
             launcher:allAppsCellHeight="104"
             launcher:startAlignTaskbar="true"
@@ -147,7 +147,7 @@
             launcher:minWidthDps="359"
             launcher:minHeightDps="567"
             launcher:iconImageSize="60"
-            launcher:iconTextSize="12.0"
+            launcher:iconTextSize="0"
             launcher:allAppsBorderSpace="16"
             launcher:allAppsCellHeight="104"
             launcher:startAlignTaskbar="true"
@@ -159,7 +159,7 @@
             launcher:minWidthDps="335"
             launcher:minHeightDps="567"
             launcher:iconImageSize="60"
-            launcher:iconTextSize="12.0"
+            launcher:iconTextSize="0"
             launcher:allAppsBorderSpace="16"
             launcher:allAppsCellHeight="104"
             launcher:startAlignTaskbar="true"
NOVA_PATCH_EOF
  cat > "$WORK/Launcher3/nova-app-anim.patch" <<'NOVA_PATCH_EOF'
diff --git a/quickstep/res/interpolator/app_open_x.xml b/quickstep/res/interpolator/app_open_x.xml
index 5fa0bcb..9deb5d7 100644
--- a/quickstep/res/interpolator/app_open_x.xml
+++ b/quickstep/res/interpolator/app_open_x.xml
@@ -1,21 +1,9 @@
 <?xml version="1.0" encoding="utf-8"?>
 <!--
-/*
-** Copyright 2021, The Android Open Source Project
-**
-** Licensed under the Apache License, Version 2.0 (the "License");
-** you may not use this file except in compliance with the License.
-** You may obtain a copy of the License at
-**
-**     http://www.apache.org/licenses/LICENSE-2.0
-**
-** Unless required by applicable law or agreed to in writing, software
-** distributed under the License is distributed on an "AS IS" BASIS,
-** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-** See the License for the specific language governing permissions and
-** limitations under the License.
-*/
+  Nova: iOS-style app-open curve.
+  Stock is a long, late-decelerating sweep (0.1217, 0.0462, 0.15, 0.4686, 0.1667, 0.66,
+  0.1834, 0.8878, 0.1667, 1, 1, 1) that keeps moving until almost the end.
+  iOS opens fast and settles early: cubic-bezier(0.32, 0.72, 0, 1).
 -->
-
 <pathInterpolator xmlns:android="http://schemas.android.com/apk/res/android"
-    android:pathData="M 0, 0 C 0.1217, 0.0462, 0.15, 0.4686, 0.1667, 0.66 C 0.1834, 0.8878, 0.1667, 1, 1, 1"/>
+    android:pathData="M 0,0 C 0.32,0.72 0,1 1,1" />
diff --git a/quickstep/src/com/android/launcher3/QuickstepTransitionManager.java b/quickstep/src/com/android/launcher3/QuickstepTransitionManager.java
index 4fe7c2c..4bd9aa0 100644
--- a/quickstep/src/com/android/launcher3/QuickstepTransitionManager.java
+++ b/quickstep/src/com/android/launcher3/QuickstepTransitionManager.java
@@ -203,7 +203,7 @@ public class QuickstepTransitionManager implements OnDeviceProfileChangeListener
      */
     public static final int STATUS_BAR_TRANSITION_PRE_DELAY = 96;
 
-    public static final long APP_LAUNCH_DURATION = 500;
+    public static final long APP_LAUNCH_DURATION = 400;   // Nova: iOS opens in ~0.4s
 
     private static final long APP_LAUNCH_ALPHA_DURATION = 50;
     private static final long APP_LAUNCH_ALPHA_START_DELAY = 25;
@@ -219,7 +219,7 @@ public class QuickstepTransitionManager implements OnDeviceProfileChangeListener
 
     public static final int RECENTS_LAUNCH_DURATION = 336;
     private static final int LAUNCHER_RESUME_START_DELAY = 100;
-    private static final int CLOSING_TRANSITION_DURATION_MS = 250;
+    private static final int CLOSING_TRANSITION_DURATION_MS = 300;   // Nova: iOS close is slower than stock
     public static final int SPLIT_LAUNCH_DURATION = 370;
     public static final int SPLIT_DIVIDER_ANIM_DURATION = 100;
 
diff --git a/res/interpolator/emphasized_interpolator.xml b/res/interpolator/emphasized_interpolator.xml
new file mode 100644
index 0000000..1bcad8c
--- /dev/null
+++ b/res/interpolator/emphasized_interpolator.xml
@@ -0,0 +1,8 @@
+<?xml version="1.0" encoding="utf-8"?>
+<!--
+  Nova: overrides the shared emphasised interpolator inside Launcher3 only, so the
+  crop/scale/alpha properties follow the same iOS curve as app_open_x.
+  Same cubic-bezier(0.32, 0.72, 0, 1).
+-->
+<pathInterpolator xmlns:android="http://schemas.android.com/apk/res/android"
+    android:pathData="M 0,0 C 0.32,0.72 0,1 1,1" />
NOVA_PATCH_EOF
}

FAILED=0
CHANGED=()   # repos where a patch was actually applied/reverted

# apply_patches <repo dir> <commit message> <patch file>...
apply_patches() {
  local dir="$1" msg="$2"; shift 2
  local repo="$TOP/$dir" p name applied=0
  echo; echo "== $dir =="
  if [ ! -d "$repo" ]; then fail "$dir not found under $TOP"; FAILED=1; return; fi
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then fail "$dir is not a git repo"; FAILED=1; return; fi

  for p in "$@"; do
    name="$(basename "$p")"
    case "$MODE" in
      revert)
        if git -C "$repo" apply -R --check "$WORK/$p" 2>/dev/null; then
          git -C "$repo" apply -R "$WORK/$p" && { ok "reverted $name"; applied=1; } || { fail "revert $name"; FAILED=1; }
        else skip "$name is not applied (nothing to revert)"; fi ;;
      check)
        if git -C "$repo" apply --check "$WORK/$p" 2>/dev/null; then ok "$name applies cleanly"
        elif git -C "$repo" apply -R --check "$WORK/$p" 2>/dev/null; then skip "$name already applied"
        else fail "$name does not apply"; git -C "$repo" apply --check "$WORK/$p" 2>&1 | sed 's/^/        /'; FAILED=1; fi ;;
      apply)
        if git -C "$repo" apply --check "$WORK/$p" 2>/dev/null; then
          git -C "$repo" apply "$WORK/$p" && { ok "applied $name"; applied=1; } || { fail "apply $name"; FAILED=1; }
        elif git -C "$repo" apply -R --check "$WORK/$p" 2>/dev/null; then skip "$name already applied"
        else fail "$name does not apply cleanly"; git -C "$repo" apply --check "$WORK/$p" 2>&1 | sed 's/^/        /'; FAILED=1; fi ;;
    esac
  done

  if [ "$MODE" = apply ] && [ "$applied" = 1 ] && [ "$COMMIT" = 1 ]; then
    git -C "$repo" commit -qam "$msg" && ok "committed: $msg" || { fail "commit failed in $dir"; FAILED=1; }
    CHANGED+=("$dir")
  fi
}

extract

apply_patches frameworks/base       "Nova: control centre layout in QS"      frameworks_base/nova-wire-cc.patch
apply_patches packages/apps/Settings "Nova: iOS grouped settings"            Settings/nova-ios-settings.patch
apply_patches packages/apps/Launcher3 "Nova: no labels, iOS app animation"   Launcher3/nova-home-labels.patch Launcher3/nova-app-anim.patch

# Patch 1 needs these two files, which live in your fork (not in the patch).
if [ "$MODE" != revert ]; then
  for f in NovaControlCenter.kt NovaVerticalSlider.kt; do
    [ -f "$TOP/frameworks/base/packages/SystemUI/src/com/android/systemui/qs/nova/$f" ] \
      || echo "${Y}[WARN]${N} frameworks/base is missing qs/nova/$f — patch 1 will not build without it"
  done
fi

if [ "$PUSH" = 1 ] && [ "$MODE" = apply ]; then
  echo
  for d in "${CHANGED[@]}"; do
    if git -C "$TOP/$d" push "$REMOTE" "HEAD:$BRANCH"; then ok "pushed $d -> $REMOTE/$BRANCH"
    else fail "push failed for $d"; FAILED=1; fi
  done
fi

echo
if [ "$FAILED" = 0 ]; then
  echo "${G}Done.${N}"
  [ "$MODE" = apply ] && cat <<'EOT'
Build next:
  m SystemUI            # patch 1
  m Settings            # patch 2
  m Launcher3QuickStep  # patches 3 and 4
  brunch lineage_<device>
EOT
else
  echo "${R}Finished with errors — see above.${N}"; exit 1
fi
