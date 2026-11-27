diff --git a/packages/apps/Launcher3/res/values/config.xml b/packages/apps/Launcher3/res/values/config.xml
index e7ec0a0..1b2c3d4 100644
--- a/packages/apps/Launcher3/res/values/config.xml
+++ b/packages/apps/Launcher3/res/values/config.xml
@@ -22,20 +22,20 @@
 
     <!-- Values for icon shape overrides. These should correspond to entries defined in
          icon_shape_override_paths_names -->
     <string-array translatable="false" name="icon_shape_override_paths_values">
-        <item></item>
-        <item>M50,0L100,0 100,100 0,100 0,0z</item>
-        <item>M50,0 C10,0 0,10 0,50 0,90 10,100 50,100 90,100 100,90 100,50 100,10 90,0 50,0 Z</item>
-        <item>M50 0A50 50,0,1,1,50 100A50 50,0,1,1,50 0</item>
-        <item>M50,0A50,50,0,0 1 100,50 L100,85 A15,15,0,0 1 85,100 L50,100 A50,50,0,0 1 50,0z</item>
+        <!-- Squircle (iOS-style) is now the only supported shape -->
+        <item>M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z</item>
+        <item>M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z</item>
+        <item>M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z</item>
+        <item>M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z</item>
+        <item>M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z</item>
     </string-array>
     <string-array translatable="false" name="icon_shape_override_paths_names">
         <!-- Option to not change the icon shape on home screen. [CHAR LIMIT=50] -->
-        <item>@string/icon_shape_system_default</item>
-        <item>@string/icon_shape_square</item>
-        <item>@string/icon_shape_squircle</item>
-        <item>@string/icon_shape_circle</item>
-        <item>@string/icon_shape_teardrop</item>
+        <item>@string/icon_shape_squircle</item>
+        <item>@string/icon_shape_squircle</item>
+        <item>@string/icon_shape_squircle</item>
+        <item>@string/icon_shape_squircle</item>
+        <item>@string/icon_shape_squircle</item>
     </string-array>
     <!-- DragController -->
     <item type="id" name="drag_event_parity" />
diff --git a/packages/apps/Launcher3/src/com/android/launcher3/graphics/IconShapeOverride.java b/packages/apps/Launcher3/src/com/android/launcher3/graphics/IconShapeOverride.java
index 654fa98..a1b2c3d 100644
--- a/packages/apps/Launcher3/src/com/android/launcher3/graphics/IconShapeOverride.java
+++ b/packages/apps/Launcher3/src/com/android/launcher3/graphics/IconShapeOverride.java
@@ -43,7 +43,9 @@ public class IconShapeOverride {
     private static final String TAG = "IconShapeOverride";
     public static final String KEY_PREFERENCE = "pref_override_icon_shape";
 
-    private static final String DEFAULT_PATH = "M50 0A50 50,0,1,1,50 100A50 50,0,1,1,50 0";
+    // Default to squircle (iOS-style)
+    private static final String DEFAULT_PATH = 
+        "M50,0 C15,0 0,15 0,50 C0,85 15,100 50,100 C85,100 100,85 100,50 C100,15 85,0 50,0 Z";
 
     public static void apply(Context context) {
         if (!(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)) {
@@ -117,7 +119,8 @@ public class IconShapeOverride {
     }
 
     private static String getAppliedValue(Context context) {
-        return getDevicePrefs(context).getString(KEY_PREFERENCE, DEFAULT_PATH);
+        // Always return the squircle path, ignoring any user preference
+        return DEFAULT_PATH;
     }
 
     private static SharedPreferences getDevicePrefs(Context context) {
