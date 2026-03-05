# ============================================================
# ProGuard Rules for MINGRR App
# Release 빌드 시 코드 난독화에서 제외할 클래스 정의
# ============================================================

# ===== 카카오 SDK =====
# 카카오맵 SDK 클래스 유지 (난독화 제외)
-keep class com.kakao.** { *; }
-keep class com.kakao.sdk.**.model.* { <fields>; }
-keep class com.kakao.vectormap.** { *; }

# ===== OkHttp (카카오 SDK 의존성) =====
# https://github.com/square/okhttp/pull/6792
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.*
-dontwarn org.openjsse.**

# ===== Retrofit2 (with R8 full mode) =====
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <3>
-keep,allowobfuscation,allowshrinking class retrofit2.Response

# ===== Flutter =====
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ===== Firebase =====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ===== Geolocator =====
-keep class com.baseflow.geolocator.** { *; }

# ===== Google Play Core (Flutter Deferred Components) =====
# R8 빌드 시 누락되는 Play Core 클래스 처리
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
