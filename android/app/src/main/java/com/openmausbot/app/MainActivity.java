package com.openmausbot.app;

import android.webkit.PermissionRequest;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.BridgeWebChromeClient;

public class MainActivity extends BridgeActivity {
    @Override
    protected void load() {
        super.load();
        bridge.getWebView().setWebChromeClient(new BridgeWebChromeClient(bridge) {
            @Override
            public void onPermissionRequest(PermissionRequest request) {
                boolean trustedOrigin = request.getOrigin() != null
                    && "https".equalsIgnoreCase(request.getOrigin().getScheme())
                    && "openmausbot.ikamai.com".equalsIgnoreCase(request.getOrigin().getHost());
                String[] resources = request.getResources();
                if (!trustedOrigin || resources.length != 1
                    || !PermissionRequest.RESOURCE_AUDIO_CAPTURE.equals(resources[0])) {
                    request.deny();
                    return;
                }
                super.onPermissionRequest(request);
            }
        });
    }
}
