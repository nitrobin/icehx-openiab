package icehx.openiab;

interface OpenIABCallback {
    public function onServiceAvailable(available : Bool):Void;
    public function onInventoryAvailable(available : Bool):Void;
    public function onPurchase(success : Bool,  purchase:Purchase):Void;
    public function onConsume(success : Bool,  purchase:Purchase):Void;
}

