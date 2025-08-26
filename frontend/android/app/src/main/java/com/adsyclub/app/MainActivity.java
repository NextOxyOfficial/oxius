package com.adsyclub.app;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Window;
import android.view.WindowManager;
import android.graphics.Color;
import android.os.Build;
import com.getcapacitor.BridgeActivity;
import androidx.core.view.WindowInsetsControllerCompat;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Configure status bar early
        configureStatusBar();

        // Re-assert after WebView/Capacitor plugins finish initial paint
        new Handler(Looper.getMainLooper()).postDelayed(new Runnable() {
            @Override
            public void run() {
                configureStatusBar();
            }
        }, 800); // slight delay to override any late plugin changes
    }

    @Override
    public void onResume() {
        super.onResume();
        
        // Ensure status bar is configured every time the activity resumes
        configureStatusBar();
    }

    private void configureStatusBar() {
        Window window = getWindow();
        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Force white status bar
            window.setStatusBarColor(Color.WHITE);
            
            // We want DARK icons (i.e. light status bar flag must be ON) so first clear both possibilities then set
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                WindowInsetsControllerCompat controller = new WindowInsetsControllerCompat(window, window.getDecorView());
                // Clear then set to ensure consistency
                controller.setAppearanceLightStatusBars(false); // reset
                controller.setAppearanceLightStatusBars(true);  // dark icons
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                final int LIGHT_FLAG = android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                int vis = window.getDecorView().getSystemUiVisibility();
                // remove then add to avoid duplication or stale state
                vis &= ~LIGHT_FLAG;
                vis |= LIGHT_FLAG;
                window.getDecorView().setSystemUiVisibility(vis);
            }
        }
        
        // Ensure content doesn't go under status bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        }
    }
}
