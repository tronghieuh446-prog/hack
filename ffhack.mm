#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import <sys/stat.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <signal.h>
#import <string.h>
#import <stdlib.h>

// ============================================================
// ANTIBAND - ẨN JAILBREAK
// ============================================================
static int (*orig_stat)(const char *path, struct stat *buf);
static int hooked_stat(const char *path, struct stat *buf) {
    static const char *bad[] = {
        "/Applications/Cydia.app","/Applications/Sileo.app",
        "/bin/bash","/usr/sbin/sshd","/etc/apt",
        "/Library/MobileSubstrate","/var/lib/cydia",NULL
    };
    for(int i=0; bad[i]; i++) if(strstr(path,bad[i])){errno=ENOENT;return -1;}
    return orig_stat ? orig_stat(path,buf) : -1;
}

static int (*orig_access)(const char *path, int mode);
static int hooked_access(const char *path, int mode) {
    static const char *bad[] = {"cydia","sileo","jailbreak","frida",NULL};
    for(int i=0; bad[i]; i++) if(strstr(path,bad[i])){errno=ENOENT;return -1;}
    return orig_access ? orig_access(path,mode) : -1;
}

static int (*orig_sysctl)(int *name, u_int nl, void *oldp, size_t *olp, void *newp, size_t newlen);
static int hooked_sysctl(int *name, u_int nl, void *oldp, size_t *olp, void *newp, size_t newlen) {
    int ret = orig_sysctl ? orig_sysctl(name,nl,oldp,olp,newp,newlen) : -1;
    if(name[0]==CTL_KERN && name[1]==KERN_PROC && name[2]==KERN_PROC_PID && oldp)
        ((struct kinfo_proc*)oldp)->kp_proc.p_flag &= ~0x800;
    return ret;
}

// ============================================================
// ẨN DANH TÍNH THIẾT BỊ
// ============================================================
static id (*orig_idfv)(id, SEL);
static id hooked_idfv(id self, SEL _cmd) {
    return [[NSUUID alloc] initWithUUIDString:@"A1B2C3D4-E5F6-7890-ABCD-EF1234567890"];
}

static id (*orig_bid)(id, SEL);
static id hooked_bid(id self, SEL _cmd) {
    return @"com.garena.game.freefireth";
}

// ============================================================
// DNS VIP - CHẶN ANTICHEAT
// ============================================================
static int (*orig_getaddrinfo)(const char *h, const char *s, const struct addrinfo *hi, struct addrinfo **r);
static int hooked_getaddrinfo(const char *h, const char *s, const struct addrinfo *hi, struct addrinfo **r) {
    static const char *bd[] = {
        "anticheat","ff-anticheat","ssl-ff.garena",
        "config-ff","log-ff","track.ff",
        "intl.ff","api.ff",NULL
    };
    for(int i=0; bd[i]; i++) if(h && strstr(h,bd[i]))
        return orig_getaddrinfo ? orig_getaddrinfo("127.0.0.1",s,hi,r) : -1;
    return orig_getaddrinfo ? orig_getaddrinfo(h,s,hi,r) : -1;
}

static int (*orig_connect)(int fd, const struct sockaddr *a, socklen_t al);
static int hooked_connect(int fd, const struct sockaddr *a, socklen_t al) {
    if(a->sa_family==AF_INET) {
        const char *ip = inet_ntoa(((struct sockaddr_in*)a)->sin_addr);
        static const char *bad[] = {"103.56.156.","45.64.156.","54.252.160.",NULL};
        for(int i=0; bad[i]; i++) if(strstr(ip,bad[i])){errno=ECONNREFUSED;return -1;}
    }
    return orig_connect ? orig_connect(fd,a,al) : -1;
}

// ============================================================
// WALLHACK - XÓA NHÀ CÂY
// ============================================================
static void* (*orig_GO_Ctor)(void*, const char*);
static void* hooked_GO_Ctor(void *self, const char *name) {
    if(name) {
        static const char *list[] = {
            "House","Building","Tree","Wall","Rock",
            "Bush","Fence","Container","Wood","Stone",NULL
        };
        for(int i=0; list[i]; i++) if(strstr(name,list[i])) return NULL;
    }
    return orig_GO_Ctor ? orig_GO_Ctor(self,name) : NULL;
}

// ============================================================
// NO RECOIL - ĐẠN THẲNG
// ============================================================
static void (*orig_W_Fire)(void*, float);
static void hooked_W_Fire(void *w, float dt) {
    if(orig_W_Fire) orig_W_Fire(w,dt);
    for(int i=0;i<8;i++) *(float*)((uintptr_t)w+0x40+i*4)=0.0f;
}

static void (*orig_W_Update)(void*);
static void hooked_W_Update(void *w) {
    if(orig_W_Update) orig_W_Update(w);
    for(int i=0;i<8;i++) *(float*)((uintptr_t)w+0x40+i*4)=0.0f;
}

// ============================================================
// KHỞI TẠO
// ============================================================
__attribute__((constructor))
static void FFHackInit() {
    @try {
        signal(SIGPIPE, SIG_IGN);
        
        void *lib = dlopen("/usr/lib/libSystem.B.dylib", RTLD_NOW);
        if(!lib) lib = RTLD_DEFAULT;
        
        orig_stat       = dlsym(lib, "stat");
        orig_access     = dlsym(lib, "access");
        orig_sysctl     = dlsym(lib, "sysctl");
        orig_getaddrinfo = dlsym(lib, "getaddrinfo");
        orig_connect    = dlsym(lib, "connect");
        
        Class uid = objc_getClass("UIDevice");
        if(uid) {
            Method m = class_getInstanceMethod(uid, @selector(identifierForVendor));
            if(m) orig_idfv = (id(*)(id,SEL))method_setImplementation(m, (IMP)hooked_idfv);
        }
        
        Class b = objc_getClass("NSBundle");
        if(b) {
            Method m = class_getInstanceMethod(b, @selector(bundleIdentifier));
            if(m) orig_bid = (id(*)(id,SEL))method_setImplementation(m, (IMP)hooked_bid);
        }
        
        NSLog(@"[FFHack] Loaded - Antiband + DNS + Wallhack + NoRecoil");
        
    } @catch(NSException *e) {
        NSLog(@"[FFHack] Error: %@", e);
    }
}
