package com.adsyclub.app;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Window;
import android.view.WindowManager;
import android.view.View;
import android.view.ViewTreeObserver;
import android.graphics.Color;
import android.os.Build;
import com.getcapacitor.BridgeActivity;
import android.util.Log;
import androidx.core.view.WindowInsetsControllerCompat;

public class MainActivity extends BridgeActivity {
    private static final String TAG = "StatusBarForce";
    private Handler statusBarHandler;
    private Runnable statusBarRunnable;
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Force status bar immediately
        forceStatusBarStyle();
        
        // Create a handler that continuously enforces status bar style
        statusBarHandler = new Handler(Looper.getMainLooper());
        statusBarRunnable = new Runnable() {
            @Override
            public void run() {
                forceStatusBarStyle();
                // Re-run every 500ms to combat any overrides
                statusBarHandler.postDelayed(this, 500);
            }
        };
        
        // Start continuous enforcement after a short delay
        statusBarHandler.postDelayed(statusBarRunnable, 100);
    }

    @Override
    public void onResume() {
        super.onResume();
        forceStatusBarStyle();
        
        // Restart continuous enforcement when resuming
        if (statusBarHandler != null && statusBarRunnable != null) {
            statusBarHandler.removeCallbacks(statusBarRunnable);
            statusBarHandler.postDelayed(statusBarRunnable, 100);
        }
    }

    @Override
    public void onStart() {
        super.onStart();
        forceStatusBarStyle();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            forceStatusBarStyle();
        }
    }

    @Override
    protected void onPostResume() {
        super.onPostResume();
        forceStatusBarStyle();
    }
    
    @Override
    public void onPause() {
        super.onPause();
        // Stop continuous enforcement when paused
        if (statusBarHandler != null && statusBarRunnable != null) {
            statusBarHandler.removeCallbacks(statusBarRunnable);
        }
    }

    private void forceStatusBarStyle() {
        try {
            Window window = getWindow();
            if (window == null) return;
            
            // Clear any conflicting flags
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Force white status bar background
                window.setStatusBarColor(Color.WHITE);
                
                View decorView = window.getDecorView();
                if (decorView == null) return;
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // Android 11+ approach
                    WindowInsetsControllerCompat controller = new WindowInsetsControllerCompat(window, decorView);
                    controller.setAppearanceLightStatusBars(true); // Dark icons on white background
                    Log.d(TAG, "Forced modern status bar: white bg, dark icons");
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    // Android 6.0+ approach
                    int vis = decorView.getSystemUiVisibility();
                    // Remove any conflicting flags
                    vis &= ~(View.SYSTEM_UI_FLAG_FULLSCREEN | 
                            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN |
                            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY |
                            View.SYSTEM_UI_FLAG_IMMERSIVE);
                    // Add light status bar flag for dark icons
                    vis |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                    decorView.setSystemUiVisibility(vis);
                    Log.d(TAG, "Forced legacy status bar: white bg, dark icons");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error forcing status bar style", e);
        }
    }
}
