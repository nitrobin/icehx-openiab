package;

import haxe.Json;


import flash.display.Sprite;
import flash.display.Bitmap;
import flash.filters.ColorMatrixFilter;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.ui.Keyboard;
import flash.text.TextField;
import flash.Lib;

import openfl.Assets;

import icehx.openiab.OpenIABHelper;
import icehx.openiab.OpenIABCallback;
import icehx.openiab.OpenIAB;
import icehx.openiab.SkuDetails;
import icehx.openiab.Purchase;
import icehx.openiab.OpenIABCallback;

class Main extends Sprite {

    public var productIds = [];
    public var created:Bool = false;
    public var inventoryReady:Bool = false;

    public var purchases:Array<Purchase> = [];
    public var items:Array<SkuDetails> = [];

    public var purchaseSelected:ColorBtn;
    public var consumeSelected:ColorBtn;
    public var consumeAll:ColorBtn;
    public var selectNext:ColorBtn;
    public var selectPrev:ColorBtn;
    public var refresh:ColorBtn;
    public var statusLog:TextArea;
    public var resultLog:TextArea;

    var billingIcon:Sprite;

    var selectedProductIdx:Int = 0;

    public function new() {

        super();

        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);

        purchaseSelected = new ColorBtn(0xCDDB9D, "Purchase\nselected", true).move(20, 10).onClick(onPurchaseSelectedClick);
        consumeSelected = new ColorBtn(0xCDDB9D, "Consume\nselected", true).move(130, 10).onClick(onConsumeSelectedClick);
        consumeAll = new ColorBtn(0xCDDB9D, "Consume\nAll", true).move(240, 10).onClick(onConsumeAllClick);

        selectPrev = new ColorBtn(0xCDDB9D, "Prev", true).move(20, 80).onClick(onPrevClick);
        selectNext = new ColorBtn(0xCDDB9D, "Next", true).move(130, 80).onClick(onNextClick);
        refresh = new ColorBtn(0xCDDB9D, "Refresh", true).move(240, 80).onClick(onRefresh);

        statusLog = new TextArea("", 370, 370).move(20, 150);
        resultLog = new TextArea("", 370, 50).move(20, 530);

        billingIcon = new Sprite();
        billingIcon.addChild(new Bitmap(Assets.getBitmapData("assets/onepf_logo.png")));

        billingIcon.x = 340;
        billingIcon.y = 0;

        addChild(purchaseSelected);
        addChild(consumeSelected);
        addChild(consumeAll);
        addChild(selectPrev);
        addChild(selectNext);
        addChild(refresh);
        addChild(statusLog);
        addChild(resultLog);

        addChild(billingIcon);
//        var scale = Math.min(Lib.current.stage.stageWidth/width,Lib.current.stage.stageHeight/height);
        var scale = Math.min(Lib.current.stage.stageWidth/410,Lib.current.stage.stageHeight/600);
        scaleY = scaleX = scale;
        try {
            init();
        } catch (e:Dynamic) {
            trace(e);
        }
    }

    private function init():Void {

        trace("####################################################");
        trace("Start OpenIAB service");
        var json = haxe.Json.parse(Assets.getText("assets/config.json"));
        for (storeName in Reflect.fields(json.keys)) {
            var license:String = Reflect.field(json.keys, storeName);
            if(license != null && license.length > 0){
                OpenIAB.mapLicenseKey(storeName, license);
                trace('mapLicenseKey($storeName, $license)');
            }
        }
        var hasTestPurchases = false;
        for (p in cast(json.products,Array<Dynamic>)) {
            var sku:String = p.sku;
            if (sku.indexOf("//") == 0) {
                continue;
            }
            if (sku.indexOf("android.test") == 0) {
                hasTestPurchases = true;
            }
            productIds.push(sku);
            var skuMap = p.alias;
            if (skuMap != null){
                for (storeName in Reflect.fields(skuMap)) {
                    var skuAlias = Reflect.field(skuMap, storeName);
                    OpenIAB.mapSku(sku, storeName, skuAlias);
                }
            }
        }

        OpenIAB.handler = new OpenIABHandlerImpl(this);
        OpenIAB.requestCode = 10010;
        OpenIAB.verifyMode = OpenIABHelper.VERIFY_SKIP;
        OpenIAB.debugLog = true;
        OpenIAB.checkInventory = false;
        OpenIAB.preferredStoreNames = [OpenIABHelper.NAME_GOOGLE, OpenIABHelper.NAME_NOKIA, OpenIABHelper.NAME_YANDEX];

        trace('OpenIAB.requestCode: ${OpenIAB.requestCode}');
        trace('OpenIAB.verifyMode: ${OpenIAB.verifyMode}');
        trace('OpenIAB.debugLog: ${OpenIAB.debugLog}');
        trace('OpenIAB.checkInventory: ${OpenIAB.checkInventory}');
        trace('OpenIAB.preferredStoreNames: ${OpenIAB.preferredStoreNames}');
        OpenIAB.createService();

        updateInfo();

    }

    function onKeyUp(event:KeyboardEvent) {
        switch(event.keyCode)
        {
            case Keyboard.ESCAPE:
                #if sys Lib.exit(); #end
        }
    }

    function onPrevClick(event:MouseEvent) {
        trace("onPrevClick");
        selectedProductIdx = (selectedProductIdx - 1 + productIds.length) % productIds.length;
        updateInfo();
    }

    function onNextClick(event:MouseEvent) {
        trace("onNextClick");
        selectedProductIdx = (selectedProductIdx + 1) % productIds.length;
        updateInfo();
    }

    function onRefresh(event:MouseEvent) {
        trace("onRefresh");
        OpenIAB.queryInventoryAsync(productIds);
        resultLog.text.text = 'created: ${created}, inventoryReady: ${inventoryReady}.';
    }

    function onPurchaseSelectedClick(event:MouseEvent) {
        trace("onPurchaseSelectedClick");
        var productId = productIds[selectedProductIdx];
        OpenIAB.launchPurchaseFlow(productId, "Test: " + Date.now().toString());
    }

    function getPurchase(productId):Purchase {
//        for (p in purchases) {
//            if (p.sku == productId){
//                return  p;
//            }
//        }
//        return null;
        return OpenIAB.getInventoryPurchase(productId);

    }

    function getItem(productId:String):SkuDetails {
//        for (p in items) {
//            if (p.sku == productId){
//                return  p;
//            }
//        }
//        return null;
        return OpenIAB.getInventoryItem(productId);
    }

    function onConsumeSelectedClick(event:MouseEvent) {
        trace("onConsumeSelectedClick");
        var productId = productIds[selectedProductIdx];
        var product:Purchase = getPurchase(productId);
        if (product == null) {
            var productId = productIds[selectedProductIdx];
            resultLog.text.text = 'Purchase "$productId" before';
        } else {
            OpenIAB.consumeAsync(product.sku);
        }
    }

    function onConsumeAllClick(event:MouseEvent) {
        trace("onConsumeAllClick");
        for (p in purchases) {
            OpenIAB.consumeAsync(p.sku);
        }
    }

    public function updateInfo(reloadPurchasse:Bool = false):Void {
        if (created) {
            if (reloadPurchasse) {
                purchases = OpenIAB.getInventoryPurchases();
                items = OpenIAB.getInventoryItems();
                trace("########");
                trace("######## items: ######## ");
                for(i in items){
                    trace('${i.sku} | ${haxe.Json.stringify(i)}');
                }
                trace("######## purchases: ######## ");
                for(p in purchases){
                    trace('${p.sku} | ${haxe.Json.stringify(p)}');
                }
            }
            var ids = purchases.map(function(p) {return p.sku;});
            var items = ['############# productId (count)[verified]: #############'];
            for (idx in 0...productIds.length) {
                var sku = productIds[idx];
                var count = (ids.indexOf(sku) == -1 ? 0 : 1);
                var sel = (selectedProductIdx==idx? "<<<---[selected]":"");
                var line = '$sku (${count})[${OpenIAB.verifyInventoryPurchase(sku)}] ${sel}';
                items.push(line);
            }
            var productId = productIds[selectedProductIdx];
            items.push('############# product:  #############');
            items.push('${haxe.Json.stringify(getItem(productId))}');
            items.push('############# purchase:  #############');
            items.push('${haxe.Json.stringify(getPurchase(productId))}');
            items.push('ConnectedAppstoreName: ${OpenIAB.getConnectedAppstoreName()}');
            statusLog.text.text = items.join('\n');
        }
        else {
            statusLog.text.text = "BILLING SERVICE IS NOT CREATED";
        }
    }

    public function purchased(item:Purchase) {
        trace('onPurchased:');
        resultLog.text.text = 'Purchased\nproductId: ${item.sku}';
        purchases.push(item);
        updateInfo();
    }

}

class OpenIABHandlerImpl implements OpenIABCallback {
    var _m:Main;

    public function new(m:Main) {
        this._m = m;
    }

    public function onServiceAvailable(available : Bool){
        trace('onServiceCreated: $available');
        if(available) {
            _m.created = true;
            OpenIAB.queryInventoryAsync(_m.productIds);
            _m.updateInfo(true);
        }
        _m.resultLog.text.text = ('ConnectedAppstoreName: ${OpenIAB.getConnectedAppstoreName()}');
        trace('ConnectedAppstoreName: ${OpenIAB.getConnectedAppstoreName()}');
    }

    public function onInventoryAvailable(available : Bool){
        trace('onInventoryAvailable: $available');
        _m.inventoryReady = available;
        _m.updateInfo(true);
    }

    public function onPurchase(success : Bool,  purchase:Purchase){
        trace('onPurchased: $success $purchase');
        if(success) {
            _m.resultLog.text.text = 'Purchased\nproductId: ${purchase.sku}';
            _m.purchases.push(purchase);
        } else {
            _m.resultLog.text.text = 'Purchased fail';
        }
        _m.updateInfo();
    }

    public function onConsume(success : Bool,  purchase:Purchase){
        trace('onConsume: $success $purchase');
        if (success) {
            _m.resultLog.text.text = 'Consumed\nproductId: ${purchase.sku}';
        } else {
            _m.resultLog.text.text = 'Consume fail';
        }
        _m.updateInfo(true);
    }
}



class ColorBtn extends Sprite {
    public var enabled:Bool;
    public var label:TextField;
    public var color:Int;

    private static var WIDTH:Int = 64;
    private static var HEIGHT:Int = 64;

    public function new(color:Int, text:String, ?enabled:Bool = true) {
        super();

        this.enabled = enabled;
        this.color = color;
        this.label = new TextField();
        this.label.x = 10;
        this.label.y = HEIGHT / 3.0;
        this.label.text = text;
        this.label.selectable = false;

        addChild(this.label);
        setEnabled(enabled);
    }

    private function fill(clr:Int) {
        graphics.beginFill(clr);
        graphics.drawRect(0, 0, width, HEIGHT);
        graphics.endFill();
    }

    public function setEnabled(e:Bool) {
        this.enabled = e;
        if (this.enabled) {
            fill(color);
            this.useHandCursor = true;
            this.mouseEnabled = true;
        }
        else {
            fill(0xaaaaaa);
            this.useHandCursor = false;
            this.mouseEnabled = false;
        }
    }

    public function move(x, y) {
        this.x = x;
        this.y = y;
        return this;
    }

    public function onClick(handler:MouseEvent -> Void) {
        this.addEventListener(MouseEvent.CLICK, handler);
        return this;
    }
}

class TextArea extends Sprite {
    var _w:Int;
    var _h:Int;

    public var text:TextField;

    public function new(text:String, w:Int, h:Int) {
        super();
        this._w = w;
        this._h = h;

        this.text = new TextField();
        this.text.x = 2;
        this.text.y = 2;
        this.text.width = w;
        this.text.height = h;
        this.text.wordWrap = true;

        addChild(this.text);
        rect(0xff0000);
    }

    public function move(x, y) {
        this.x = x;
        this.y = y;
        return this;
    }

    public function rect(color:Int) {
        graphics.beginFill(0xdddddd);
        graphics.drawRect(0, 0, _w, _h);
        graphics.endFill();
    }
}

