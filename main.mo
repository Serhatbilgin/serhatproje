import Time "mo:base/Time";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

actor TimeCapsule {
    // Kapsül veri yapısı
    public type Capsule = {
        id: Nat;
        content: Text; 
        file: ?Blob; 
        unlockDate: Time.Time;
        owner: Principal;
    };
    
    // Kapsüllerin tutulduğu buffer
    private var capsules: Buffer.Buffer<?Capsule> = Buffer.Buffer(0);
    
    // Yeni kapsül oluşturma
    public func createCapsule(content: Text, file: ?Blob, unlockDate: Time.Time, caller: Principal) : async Capsule {
        if (content.size() == 0) {
            throw Error.reject("Content cannot be empty");
        };
        
        if (unlockDate <= Time.now()) {
            throw Error.reject("Unlock date must be in the future");
        };
        
        let newCapsule: Capsule = {
            id = capsules.size();
            content = content;
            file = file;
            unlockDate = unlockDate;
            owner = caller;
        };
        
        capsules.add(?newCapsule);
        return newCapsule;
    };
    
    // Kapsülü açma (Yalnızca sahibi erişebilir ve tarih kontrolü yapılır)
    public func openCapsule(id: Nat, caller: Principal) : async ?(Text, ?Blob) {
        if (id >= capsules.size()) {
            return null;
        };
        
        let capsuleOpt = capsules.get(id);
        switch (capsuleOpt) {
            case (null) { return null };
            case (?capsule) {
                if (capsule.owner != caller) {
                    throw Error.reject("Unauthorized access");
                };
                
                if (Time.now() < capsule.unlockDate) {
                    throw Error.reject("This capsule cannot be opened yet");
                };
                
                return ?(capsule.content, capsule.file);
            };
        };
    };
    
    // Kullanıcının tüm kapsüllerini listeleme
    public func listMyCapsules(caller: Principal) : async [Capsule] {
        let filteredCapsules = Buffer.mapFilter<Capsule, Capsule>(
            Buffer.mapFilter<?(Capsule), Capsule>(
                capsules,
                func(c: ?(Capsule)) : ?Capsule { c }
            ),
            func(c: Capsule) : ?Capsule { 
                if (c.owner == caller) { ?c } else { null }
            }
        );
        
        return Buffer.toArray(filteredCapsules);
    };
    
    // Kapsül silme (Yalnızca sahibi silebilir)
    public func deleteCapsule(id: Nat, caller: Principal) : async Bool {
        if (id >= capsules.size()) {
            return false;
        };
        
        let capsuleOpt = capsules.get(id);
        switch (capsuleOpt) {
            case (null) { return false };
            case (?capsule) {
                if (capsule.owner != caller) {
                    return false;
                };
                
                capsules.put(id, null);
                return true;
            };
        };
    };
    
    // Tüm kapsülleri listeleme (Test amaçlı)
    public func listAllCapsules() : async [Capsule] {
        Buffer.toArray(
            Buffer.mapFilter<?(Capsule), Capsule>(
                capsules, 
                func(c: ?(Capsule)) : ?Capsule { c }
            )
        );
    };
}
