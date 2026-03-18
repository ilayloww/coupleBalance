package com.couplebalance.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

class QuickAddActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String {
        return "quickAddMain"
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }
}
