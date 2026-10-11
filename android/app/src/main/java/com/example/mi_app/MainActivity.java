package com.example.mi_app;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String METHOD_CHANNEL = "com.example.mi_app/deeplink/method";
    private static final String EVENT_CHANNEL = "com.example.mi_app/deeplink/events";

    private static EventChannel.EventSink linkSink;
    private static String initialLink;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.getData() != null) {
            final String uri = intent.getData().toString();
            initialLink = uri;
            runOnUiThread(() -> {
                if (linkSink != null) {
                    linkSink.success(uri);
                }
            });
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("getInitialLink".equals(call.method)) {
                    result.success(initialLink);
                } else {
                    result.notImplemented();
                }
            });

        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    linkSink = events;
                    if (initialLink != null) {
                        events.success(initialLink);
                    }
                }

                @Override
                public void onCancel(Object arguments) {
                    linkSink = null;
                }
            });
    }
}
