package icehx.openiab;

class OpenIABHelper {
    public static inline var NAME_GOOGLE = "com.google.play";
    public static inline var NAME_AMAZON = "com.amazon.apps";
    public static inline var NAME_SAMSUNG = "com.samsung.apps";
    public static inline var NAME_YANDEX = "com.yandex.store";
    public static inline var NAME_NOKIA = "com.nokia.nstore";
    public static inline var NAME_APPLAND = "Appland";
    public static inline var NAME_SLIDEME = "SlideME";
    public static inline var NAME_APTOIDE = "cm.aptoide.pt";

    /**
     * Verify signatures in any store.
     * <p/>
     * By default in Google's IabHelper. Throws exception if key is not available or invalid.
     * To prevent crashes OpenIAB wouldn't connect to OpenStore if no publicKey provided
     */
    public static inline var VERIFY_EVERYTHING = 0;

    /**
     * Don't verify signatures. To perform verification on server-side
     */
    public static inline var VERIFY_SKIP = 1;

    /**
     * Verify signatures only if publicKey is available. Otherwise skip verification.
     * <p/>
     * Developer is responsible for verify
     */
    public static inline var VERIFY_ONLY_KNOWN = 2;

}

