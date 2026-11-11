package sn.digitalfactory.guichetplus.agent

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "sn.digitalfactory.guichetplus.agent/permissions"
    private val cameraRequestCode = 4101
    private var pendingCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "requestCamera") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
            } else {
                pendingCameraResult?.success(false)
                pendingCameraResult = result
                requestPermissions(arrayOf(Manifest.permission.CAMERA), cameraRequestCode)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == cameraRequestCode) {
            pendingCameraResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            pendingCameraResult = null
        }
    }
}
