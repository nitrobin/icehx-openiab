package icehx.openiab;


import icehx.openiab.OpenIABCallback;
import icehx.openiab.Purchase;
import icehx.openiab.SkuDetails;

#if android

//http://docs.oracle.com/javase/1.5.0/docs/guide/jni/spec/types.html

import openfl.utils.JNI;
import haxe.Json;

class CallbackProxy {
    public function new() {}

    // prevent recursive JNI calls
    private static function callLater(fun : Void -> Void) {
        haxe.Timer.delay(function() {
            try {
                fun();
            } catch(e:Dynamic) {
                trace(e);
            }
        }, 10);
    }

    public function onServiceAvailable(available : Bool) {
        callLater(function() {
            if (OpenIABAndroid.handler != null) {
                OpenIABAndroid.handler.onServiceAvailable(available);
            }
            #if msignal OpenIABAndroid.onServiceAvailable.dispatch(available);#end
        });
    }

    public function onInventoryAvailable(available : Bool) {
        callLater(function() {
            if (OpenIABAndroid.handler != null) {
                OpenIABAndroid.handler.onInventoryAvailable(available);
            }
            #if msignal OpenIABAndroid.onInventoryAvailable.dispatch(available);#end
        });
    }

    public function onPurchase(success : Bool, purchaseJson:String) {
        callLater(function() {
            var purchase:Purchase = (purchaseJson != null ? Json.parse(purchaseJson): null);
            if (OpenIABAndroid.handler != null) {
                OpenIABAndroid.handler.onPurchase(success, purchase);
            }
            #if msignal OpenIABAndroid.onPurchase.dispatch(success, purchase);#end
        });
    }

    public function onConsume(success : Bool, purchaseJson:String) {
        callLater(function() {
            var purchase:Purchase = (purchaseJson != null ? Json.parse(purchaseJson): null);
            if (OpenIABAndroid.handler != null) {
                OpenIABAndroid.handler.onConsume(success, purchase);
            }
            #if msignal OpenIABAndroid.onConsume.dispatch(success, purchase);#end
        });
    }
}

class OpenIABAndroid {
    private static var callbackProxy = new CallbackProxy();

    public static var handler:OpenIABCallback = null;
    public static var requestCode:Int = 10010;
    public static var verifyMode:Int = OpenIABHelper.VERIFY_SKIP;
    public static var debugLog:Bool = false;
    public static var preferredStoreNames:Array<String> = [];
    public static var checkInventory:Bool = false;
    public static var availableStoreNames:Array<String> = [];
    public static var storeSearchStrategy:Int  = OpenIABHelper.SEARCH_STRATEGY_INSTALLER;

    #if msignal
    public static var onServiceAvailable(default, null):msignal.Signal.Signal1<Bool> = new msignal.Signal.Signal1();
    public static var onInventoryAvailable(default, null):msignal.Signal.Signal1<Bool> = new msignal.Signal.Signal1();
    public static var onPurchase(default, null):msignal.Signal.Signal2<Bool, Purchase> = new msignal.Signal.Signal2();
    public static var onConsume(default, null):msignal.Signal.Signal2<Bool, Purchase> = new msignal.Signal.Signal2();
    #end

    public function new() {
    }

    public static function isSupported():Bool {
        return true;
    }

    public static function mapLicenseKey(storeName:String, key:String):Void {
        if (_mapLicenseKey == null) {
            _mapLicenseKey = JNI.createStaticMethod("icehx/openiab/OpenIAB", "mapLicenseKey", "(Ljava/lang/String;Ljava/lang/String;)V");
        }
        _mapLicenseKey(storeName, key);
    }

    public static function mapSku(sku:String, storeName:String, storeSku:String):Void {
        if (_mapSku == null) {
            _mapSku = JNI.createStaticMethod("icehx/openiab/OpenIAB", "mapSku", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
        }
        _mapSku(sku, storeName, storeSku);
    }

    public static function createService():Void {
        if (_createService == null) {
            _createService = JNI.createStaticMethod("icehx/openiab/OpenIAB", "createService", "(Lorg/haxe/lime/HaxeObject;IZ[Ljava/lang/String;Z[Ljava/lang/String;I)V");
        }
        _createService(callbackProxy, verifyMode, debugLog, preferredStoreNames, checkInventory, availableStoreNames, storeSearchStrategy);
    }

    public static function isServiceReady():Bool {
        if (_isServiceReady == null) {
            _isServiceReady = JNI.createStaticMethod("icehx/openiab/OpenIAB", "isServiceReady", "()Z");
        }
        return _isServiceReady();
    }

    public static function isInventoryReady():Bool {
        if (_isInventoryReady == null) {
            _isInventoryReady = JNI.createStaticMethod("icehx/openiab/OpenIAB", "isInventoryReady", "()Z");
        }
        return _isInventoryReady();
    }

    public static function hasInventoryPurchase(sku:String):Bool {
        if (_hasInventoryPurchase == null) {
            _hasInventoryPurchase = JNI.createStaticMethod("icehx/openiab/OpenIAB", "hasInventoryPurchase", "(Ljava/lang/String;)Z");
        }
        return _hasInventoryPurchase(sku);
    }

    public static function verifyInventoryPurchase(sku:String):Bool {
        if (_verifyInventoryPurchase == null) {
            _verifyInventoryPurchase = JNI.createStaticMethod("icehx/openiab/OpenIAB", "verifyInventoryPurchase", "(Ljava/lang/String;)Z");
        }
        return _verifyInventoryPurchase(sku);
    }

    public static function getConnectedAppstoreName():String {
        if (_getConnectedAppstoreName == null) {
            _getConnectedAppstoreName = JNI.createStaticMethod("icehx/openiab/OpenIAB", "getConnectedAppstoreName", "()Ljava/lang/String;");
        }
        return _getConnectedAppstoreName();
    }

    public static function queryInventoryAsync(skuIds:Array<String>):Void {
        if (_queryInventoryAsync == null) {
            _queryInventoryAsync = JNI.createStaticMethod("icehx/openiab/OpenIAB", "queryInventoryAsync", "([Ljava/lang/String;)V");
        }
        _queryInventoryAsync(skuIds);
    }

    public static function getInventoryItems():Array<SkuDetails> {
        if (_getInventoryItems == null) {
            _getInventoryItems = JNI.createStaticMethod("icehx/openiab/OpenIAB", "getInventoryItems", "()[Ljava/lang/String;");
        }
        var infos:Array<SkuDetails> = Lambda.array(Lambda.map(_getInventoryItems(), Json.parse));
        return infos;
    }

    public static function getInventoryPurchases():Array<Purchase> {
        if (_getInventoryPurchases == null) {
            _getInventoryPurchases = JNI.createStaticMethod("icehx/openiab/OpenIAB", "getInventoryPurchases", "()[Ljava/lang/String;");
        }
        var infos:Array<Purchase> = Lambda.array(Lambda.map(_getInventoryPurchases(), Json.parse));
        return infos;
    }

    public static function getInventoryItem(sku:String):SkuDetails {
        if (_getInventoryItem == null) {
            _getInventoryItem = JNI.createStaticMethod("icehx/openiab/OpenIAB", "getInventoryItem", "(Ljava/lang/String;)Ljava/lang/String;");
        }
        var itemJson:String = _getInventoryItem(sku);
        return itemJson != null ? Json.parse(itemJson): null;
    }

    public static function getInventoryPurchase(sku:String):Purchase {
        if (_getInventoryPurchase == null) {
            _getInventoryPurchase = JNI.createStaticMethod("icehx/openiab/OpenIAB", "getInventoryPurchase", "(Ljava/lang/String;)Ljava/lang/String;");
        }
        var itemJson:String = _getInventoryPurchase(sku);
        return itemJson != null ? Json.parse(itemJson): null;
    }

    public static function launchPurchaseFlow(sku:String, ?extraData:String):Void {
        if (_launchPurchaseFlow == null) {
            _launchPurchaseFlow = JNI.createStaticMethod("icehx/openiab/OpenIAB", "launchPurchaseFlow", "(Ljava/lang/String;ILjava/lang/String;)V");
        }
        _launchPurchaseFlow(sku, requestCode, extraData);
    }

    public static function consumeAsync(skuId:String):Void {
        if (_consumeAsync == null) {
            _consumeAsync = JNI.createStaticMethod("icehx/openiab/OpenIAB", "consumeAsync", "(Ljava/lang/String;)V");
        }
        _consumeAsync(skuId);
    }

    private static var _mapLicenseKey:Dynamic = null;
    private static var _mapSku:Dynamic = null;
    private static var _createService:Dynamic = null;
    private static var _destroyService:Dynamic = null;
    private static var _isServiceReady:Dynamic = null;
    private static var _isInventoryReady:Dynamic = null;
    private static var _hasInventoryPurchase:Dynamic = null;
    private static var _verifyInventoryPurchase:Dynamic = null;
    private static var _getConnectedAppstoreName:Dynamic = null;
    private static var _queryInventoryAsync:Dynamic = null;
    private static var _getInventoryItems:Dynamic = null;
    private static var _getInventoryPurchases:Dynamic = null;
    private static var _getInventoryItem:Dynamic = null;
    private static var _getInventoryPurchase:Dynamic = null;
    private static var _launchPurchaseFlow:Dynamic = null;
    private static var _consumeAsync:Dynamic = null;

}

typedef OpenIAB = OpenIABAndroid;

#else

class OpenIABFallback
{
    public static var handler:OpenIABCallback = null;
    public static var requestCode:Int = 10010;
    public static var verifyMode:Int = OpenIABHelper.VERIFY_SKIP;
    public static var debugLog:Bool = false;
    public static var preferredStoreNames:Array<String> = [];
    public static var checkInventory:Bool = false;
    public static var availableStoreNames:Array<String> = [];
    public static var storeSearchStrategy:Int  = OpenIABHelper.SEARCH_STRATEGY_INSTALLER;

    #if msignal
    public static var onServiceAvailable(default, null):msignal.Signal.Signal1<Bool> = new msignal.Signal.Signal1();
    public static var onInventoryAvailable(default, null):msignal.Signal.Signal1<Bool> = new msignal.Signal.Signal1();
    public static var onPurchase(default, null):msignal.Signal.Signal2<Bool, Purchase> = new msignal.Signal.Signal2();
    public static var onConsume(default, null):msignal.Signal.Signal2<Bool, Purchase> = new msignal.Signal.Signal2();
    #end

    public static function isSupported():Bool {
        return false;
    }

    public static function mapLicenseKey(storeName:String, key:String):Void {
    }

    public static function mapSku(sku:String, storeName:String, storeSku:String):Void {
    }

    public static function createService():Void {
    }

    public static function isServiceReady():Bool {
        return false;
    }

    public static function isInventoryReady():Bool {
        return false;
    }

    public static function hasInventoryPurchase(sku:String):Bool {
        return false;
    }

    public static function verifyInventoryPurchase(sku:String):Bool {
        return false;
    }

    public static function getConnectedAppstoreName():String {
        return null;
    }

    public static function queryInventoryAsync(skuIds:Array<String>):Void {
    }

    public static function getInventoryItems():Array<SkuDetails> {
        return [];
    }

    public static function getInventoryPurchases():Array<Purchase> {
        return [];
    }

    public static function getInventoryItem(sku:String):SkuDetails {
        return null;
    }

    public static function getInventoryPurchase(sku:String):Purchase {
        return null;
    }

    public static function launchPurchaseFlow(sku:String, ?extraData:String):Void {
    }

    public static function consumeAsync(skuId:String):Void {
    }

}

typedef OpenIAB = OpenIABFallback;

#end
