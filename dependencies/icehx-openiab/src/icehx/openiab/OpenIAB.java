package icehx.openiab;

import org.json.JSONException;
import org.onepf.oms.OpenIabHelper;
import org.onepf.oms.SkuManager;
import org.onepf.oms.appstore.googleUtils.*;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;


import java.lang.Object;
import java.lang.String;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.json.JSONObject;


import org.haxe.lime.HaxeObject;
import org.haxe.extension.Extension;
import org.onepf.oms.util.Logger;

public class OpenIAB extends Extension {
    // Debug tag, for logging
    static final String TAG = "icehx-openiab";

    public OpenIAB() {
        super();
        Log_d("Construct icehx-openiab");
    }

    /**
     * Called when an activity you launched exits, giving you the requestCode
     * you started it with, the resultCode it returned, and any additional data
     * from it.
     */
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        return handleActivityResult(requestCode, resultCode, data);
    }


    /**
     * Called when the activity is starting.
     */
    public void onCreate(Bundle savedInstanceState) {
    }


    /**
     * Perform any final cleanup before an activity is destroyed.
     */
    public void onDestroy() {
        destroyService();
    }


    /**
     * Called as part of the activity lifecycle when an activity is going into
     * the background, but has not (yet) been killed.
     */
    public void onPause() {
    }


    /**
     * Called after {@link #onStop} when the current activity is being
     * re-displayed to the user (the user has navigated back to it).
     */
    public void onRestart() {
    }


    /**
     * Called after {@link #onRestart}, or {@link #onPause}, for your activity
     * to start interacting with the user.
     */
    public void onResume() {
    }


    /**
     * Called after {@link #onCreate} &mdash; or after {@link #onRestart} when
     * the activity had been stopped, but is now again being displayed to the
     * user.
     */
    public void onStart() {
    }


    /**
     * Called when the activity is no longer visible to the user, because
     * another activity has been resumed and is covering this one.
     */
    public void onStop() {
    }

    private static final Map<String, String> STORE_KEYS_MAP = new HashMap<String, String>();

    // The helper object
    private static OpenIabHelper mHelper = null;

    private static Inventory inventory = null;

    // is bililng setup is completed
    private static boolean setupDone = false;
    private static boolean inventoryDone = false;
    private static boolean debugLog = false;

    private static HaxeObject callback;

    private static void callback_call(final String method, final Object[] params) {
        Extension.callbackHandler.post(new Runnable() {
            @Override
            public void run() {
                try {
                    callback.call(method, params);
                } catch (Throwable e) {
                    e.printStackTrace();
                }
            } // run
        });
    }

    public static void mapLicenseKey(String storeName, String key) {
        if (mHelper != null) {
            Log_w("Service already started");
        } else {
            STORE_KEYS_MAP.put(storeName, key);
        }
    }

    public static void mapSku(String sku, String storeName, String storeSku) {
        //Only map SKUs for stores where SKU that using in app different from described in store console.
        SkuManager.getInstance().mapSku(sku, storeName, storeSku);
    }

    private static void notifyServiceAvailable(boolean available) {
        callback_call("onServiceAvailable", new Object[]{available});
    }

    private static void notifyInventoryAvailable(boolean availabel) {
        callback_call("onInventoryAvailable", new Object[]{availabel});
    }

    private static void notifyPurchase(boolean success, Purchase purchase) {
        callback_call("onPurchase", new Object[]{success, purchaseToJson(purchase)});
    }

    private static void notifyConsume(boolean success, Purchase purchase) {
        callback_call("onConsume", new Object[]{success, purchaseToJson(purchase)});
    }

    private static boolean handleActivityResult(final int requestCode, int resultCode, Intent data) {
        Log_d("onActivityResult() requestCode: " + requestCode + " resultCode: " + resultCode + " data: " + data);

        // Pass on the activity result to the helper for handling
        if (mHelper != null && mHelper.handleActivityResult(requestCode, resultCode, data)) {
            Log_d("onActivityResult handled by IABUtil.");
            return false;
        } else {
            // not handled, so handle it ourselves (here's where you'd
            // perform any handling of activity results not related to in-app
            // billing...
            return true;
        }
    }

    public static void createService(final HaxeObject callback,
                                     final int verifyMode,
                                     final boolean debugLog,
                                     final String[] preferredStoreNames,
                                     final boolean checkInventory,
                                     final String[] availableStoreNames,
                                     final int storeSearchStrategy) {
        Extension.callbackHandler.post(new Runnable() {
            @Override
            public void run() {
                try {
                    _createService(callback, verifyMode, debugLog, preferredStoreNames, checkInventory, availableStoreNames, storeSearchStrategy);
                } catch (Throwable e) {
                    e.printStackTrace();
                }
            } // run
        });
    }

    public static void _createService(final HaxeObject callback,
                                     int verifyMode,
                                     boolean debugLog,
                                     String[] preferredStoreNames,
                                     boolean checkInventory,
                                     String[] availableStoreNames,
                                     int storeSearchStrategy) {
        try {
            OpenIAB.debugLog = debugLog;
            if (mHelper != null) {
                Log_w("Service already started");
            }

            // Clear inventory
            OpenIAB.inventory = new Inventory();
            OpenIAB.callback = callback;

            // enable debug logging (for a production application, you should set this to false).
            Logger.setLoggable(debugLog);

            // Create the helper, passing it our context and the public key to verify signatures with
            Log_d("Creating IAB helper.");
            //Only map SKUs for stores that using purchase with SKUs different from described in store console.
            OpenIabHelper.Options.Builder builder = new OpenIabHelper.Options.Builder();
            builder.setCheckInventory(checkInventory);
            builder.setVerifyMode(verifyMode);
            builder.addStoreKeys(STORE_KEYS_MAP);
            if (preferredStoreNames != null && preferredStoreNames.length > 0) {
                builder.addPreferredStoreName(preferredStoreNames);
            }
            if (availableStoreNames != null && availableStoreNames.length > 0) {
                builder.addAvailableStoreNames(availableStoreNames);
            }
            builder.setStoreSearchStrategy(storeSearchStrategy);

            mHelper = new OpenIabHelper(mainContext, builder.build());


            // Start setup. This is asynchronous and the specified listener
            // will be called once setup completes.
            Log_d("Starting setup.");
            mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
                public void onIabSetupFinished(IabResult result) {
                    Log_d("Setup finished.");
                    if (result.isSuccess()) {
                        // Hooray, IAB is fully set up. Now, let's get an inventory of stuff we own.
                        Log_d("Setup successful. Querying inventory.");
                        setupDone = true;
                    } else {
                        // Oh noes, there was a problem.
                        setupDone = false;
                        Log_e("**** Error: Problem setting up in-app billing: " + result);
                        Toast.makeText(mainContext, "Problem setting up in-app billing: " + result, Toast.LENGTH_SHORT).show();
                    }
                    notifyServiceAvailable(result.isSuccess());
                }
            });
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    public static boolean isServiceReady() {
        return mHelper != null && setupDone;
    }

    public static boolean isInventoryReady() {
        return mHelper != null && setupDone && inventory != null && inventoryDone;
    }

    private static boolean hasInventory() {
        return mHelper != null && setupDone && inventory != null;
    }

    public static String getConnectedAppstoreName() {
        return mHelper != null ? mHelper.getConnectedAppstoreName() : null;
    }

    private static void destroyService() {
        try {
            // very important:
            Log_d("Destroying helper.");
            if (mHelper != null) {
                mHelper.dispose();
                mHelper = null;
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }


    public static void queryInventoryAsync(String[] skuIds) {
        try {
            if (isServiceReady()) {
                mHelper.queryInventoryAsync(true, Arrays.asList(skuIds), mGotInventoryListener);
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    // Listener that's called when we finish querying the items and subscriptions we own
    private static IabHelper.QueryInventoryFinishedListener mGotInventoryListener =
            new IabHelper.QueryInventoryFinishedListener() {
                @Override
                public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
                    OpenIAB.inventory = inventory;
                    Log_d("Query inventory finished.");
                    if (result.isSuccess()) {
                        Log_d("Query inventory was successful.");
                        inventoryDone = true;
                    } else {
                        Log_e("**** Error: Failed to query inventory: " + result);
                        Toast.makeText(mainContext, "Error: Failed to query inventory: " + result, Toast.LENGTH_SHORT).show();
                    }
                    notifyInventoryAvailable(result.isSuccess());
                }
            };

    public static String[] getInventoryItems() {
        if (hasInventory()) {
            String[] result = new String[inventory.getSkuMap().size()];
            int i = 0;
            for (SkuDetails detail : inventory.getSkuMap().values()) {
                result[i] = detailToJson(detail);
                i++;
            }
            return result;
        }
        return new String[0];
    }

    public static String[] getInventoryPurchases() {
        if (hasInventory()) {
            String[] result = new String[inventory.getPurchaseMap().size()];
            int i = 0;
            for (Purchase detail : inventory.getPurchaseMap().values()) {
                result[i] = purchaseToJson(detail);
                i++;
            }
            return result;
        }
        return new String[0];
    }

    public static String getInventoryItem(String sku) {
        if (hasInventory()) {
            return detailToJson(inventory.getSkuDetails(sku));
        }
        return "null";
    }

    public static String getInventoryPurchase(String sku) {
        if (hasInventory()) {
            return purchaseToJson(inventory.getPurchase(sku));
        }
        return "null";
    }

    public static boolean hasInventoryPurchase(String sku) {
        return hasInventory() && inventory.hasPurchase(sku);
    }

    public static boolean verifyInventoryPurchase(String sku) {
        try {
            if (hasInventory() && inventory.hasPurchase(sku)) {
                Purchase p = inventory.getPurchase(sku);
                String base64Key = STORE_KEYS_MAP.get(mHelper.getConnectedAppstoreName());
                if (p.getSku().startsWith("android.test.")) {
                    return true;
                }
                return Security.verifyPurchase(base64Key, p.getOriginalJson(), p.getSignature());
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
        return false;
    }

    public static void launchPurchaseFlow(String sku, int requestCode, String extraData) {
        try {
            if (isServiceReady()) {
                if (extraData == null) {
                    extraData = "";
                }
                mHelper.launchPurchaseFlow(mainActivity, sku, requestCode, mPurchaseFinishedListener, extraData);
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    // Callback for when a purchase is finished
    static IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = new IabHelper.OnIabPurchaseFinishedListener() {
        public void onIabPurchaseFinished(IabResult result, Purchase purchase) {
            Log_d("Purchase finished: " + result + ", purchase: " + purchase);
            if (result.isSuccess() && hasInventory() && purchase != null) {
                inventory.addPurchase(purchase);
            }
            notifyPurchase(result.isSuccess(), purchase);
            Log_d("End purchase flow.");
        }
    };

    public static void consumeAsync(String sku) {
        try {
            if (hasInventory()) {
                Purchase purchase = inventory.getPurchase(sku);
                if (purchase != null) {
                    mHelper.consumeAsync(purchase, mConsumeFinishedListener);
                }
            }
        } catch (Throwable e) {
            e.printStackTrace();
        }
    }

    // Called when consumption is complete
    static IabHelper.OnConsumeFinishedListener mConsumeFinishedListener = new IabHelper.OnConsumeFinishedListener() {
        public void onConsumeFinished(Purchase purchase, IabResult result) {
            Log_d("Consumption finished. Purchase: " + purchase + ", result: " + result);
            if (result.isSuccess() && hasInventory() && purchase != null) {
                inventory.erasePurchase(purchase.getSku());
            }
            notifyConsume(result.isSuccess(), purchase);
            Log_d("End consumption flow.");
        }
    };

    private static String detailToJson(SkuDetails detail) {
        if (detail == null) {
            return null;
        }
        JSONObject json = new JSONObject();
        try {
            json.put("sku", detail.getSku());
            json.put("description", detail.getDescription());
            json.put("price", detail.getPrice());
            json.put("title", detail.getTitle());
            json.put("type", detail.getType());
            json.put("itemType", detail.getItemType());
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return json.toString();
    }

    private static String purchaseToJson(Purchase purchase) {
        if (purchase == null) {
            return null;
        }
        JSONObject json = new JSONObject();
        try {
            json.put("sku", purchase.getSku());
            json.put("appstoreName", purchase.getAppstoreName());
            json.put("developerPayload", purchase.getDeveloperPayload());
            json.put("purchaseState", "" + purchase.getPurchaseState());
            json.put("purchaseTime", "" + purchase.getPurchaseTime());
            json.put("orderId", purchase.getOrderId());
            json.put("signature", purchase.getSignature());
            json.put("token", purchase.getToken());
            json.put("packageName", purchase.getPackageName());
            json.put("itemType", purchase.getItemType());
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return json.toString();
    }

    private static void Log_w(String msg) {
        if (debugLog) Log.w(TAG, msg);
    }

    private static void Log_d(String msg) {
        if (debugLog) Log.d(TAG, msg);
    }

    private static void Log_e(String msg) {
        if (debugLog) Log.e(TAG, msg);
    }

}
