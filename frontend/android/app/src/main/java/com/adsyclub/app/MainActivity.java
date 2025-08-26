package com.adsyclub.app;

import android.os.Bundle;
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
        
        // Configure status bar
        configureStatusBar();
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
            
            // Use modern approach for light status bar
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ modern approach
                WindowInsetsControllerCompat controller = new WindowInsetsControllerCompat(window, window.getDecorView());
                controller.setAppearanceLightStatusBars(true);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Android 6.0+ approach
                window.getDecorView().setSystemUiVisibility(
                    window.getDecorView().getSystemUiVisibility() | 
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
                );
            }
        }
        
        // Ensure content doesn't go under status bar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        }
    }
}
