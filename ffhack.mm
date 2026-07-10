#include <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <UIKit/UIKit.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <mach/mach.h>
#include <signal.h>

#define MSHookFunction(s,h,o) (*(o) = (typeof(*(o)))dlsym(RTLD_DEFAULT, #s), (void)(*(o) = (typeof(*(o)))(h)))
#define MSHookMessageEx(c,s,i,o) (*(o) = (IMP)method_setImplementation(class_getInstanceMethod(c,s),(IMP)(i)))

static int (*orig_stat)(const char *path, struct stat *buf);
static int hooked_stat(const char *path, struct stat *buf) {
    const char* bl[] = {"/Applications/Cydia.app","/bin/bash","/usr/sbin/sshd","/etc/apt","/Library/MobileSubstrate","/var/lib/cydia",NULL};
    for(int i=0; bl[i]; i++) if(strstr(path,bl[i])){errno=ENOENT;return -1;}
    return orig_stat ? orig_stat(path,buf) : -1;
}

static int (*orig_access)(const char *path, int mode);
static int hooked_access(const char *path, int mode) {
    const char* fb[] = {"cydia","sileo","jailbreak","frida",NULL};
    for(int i=0; fb[i]; i++) if(strstr(path,fb[i])){errno=ENOENT;return -1;}
    return orig_access ? orig_access(path,mode) : -1;
}

static int (*orig_sysctl)(int *name, u_int nl, void *oldp, size_t *olp, void *newp, size_t newlen);
static int hooked_sysctl(int *name, u_int nl, void *oldp, size_t *olp, void *newp, size_t newlen) {
    int ret = orig_sysctl ? orig_sysctl(name,nl,oldp,olp,newp,newlen) : -1;
    if(name[0]==CTL_KERN && name[1]==KERN_PROC && name[2]==KERN_PROC_PID && oldp)
        ((struct kinfo_proc*)oldp)->kp_proc.p_flag &= ~0x800;
    return ret;
}

static int (*orig_getaddrinfo)(const char *h, const char *s, const struct addrinfo *hi, struct addrinfo **r);
static int hooked_getaddrinfo(const char *h, const char *s, const struct addrinfo *hi, struct addrinfo **r) {
    const char* bd[] = {"anticheat","ff-anticheat","ssl-ff.garena","config-ff","log-ff",NULL};
    for(int i=0; bd[i]; i++) if(strstr(h,bd[i])) return orig_getaddrinfo ? orig_getaddrinfo("127.0.0.1",s,hi,r) : -1;
    return orig_getaddrinfo ? orig_getaddrinfo(h,s,hi,r) : -1;
}

static int (*orig_connect)(int fd, const struct sockaddr *a, socklen_t al);
static int hooked_connect(int fd, const struct sockaddr *a, socklen_t al) {
    if(a->sa_family==AF_INET) {
        const char* ips[] = {"103.56.156.10","45.64.156.20","54.252.160.35",NULL};
        for(int i=0; ips[i]; i++) if(strcmp(inet_ntoa(((struct sockaddr_in*)a)->sin_addr),ips[i])==0) {errno=ECONNREFUSED;return -1;}
    }
    return orig_connect ? orig_connect(fd,a,al) : -1;
}

static id (*orig_idfv)(id,SEL);
static id hooked_idfv(id self, SEL _cmd) { return [[NSUUID alloc] initWithUUIDString:@"A1B2C3D4-E5F6-7890-ABCD-EF1234567890"]; }
static id (*orig_bid)(id,SEL);
static id hooked_bid(id self, SEL _cmd) { return @"com.garena.game.freefireth"; }

static void* (*orig_GO_Ctor)(void*,const char*);
void* hooked_GO_Ctor(void* self, const char* name) {
    if(name) {
        const char* list[] = {"House","Building","Tree","Wall","Rock","Bush","Fence","Container",NULL};
        for(int i=0; list[i]; i++) if(strstr(name,list[i])) return NULL;
    }
    return orig_GO_Ctor ? orig_GO_Ctor(self,name) : NULL;
}

typedef void (*WF)(void*,float);
static WF orig_WF = NULL;
void hooked_WF(void* w, float dt) {
    if(orig_WF) orig_WF(w,dt);
    *(float*)((uintptr_t)w+0x40)=0; *(float*)((uintptr_t)w+0x44)=0;
    *(float*)((uintptr_t)w+0x48)=0; *(float*)((uintptr_t)w+0x4C)=0;
}

__attribute__((constructor)) void FFInit() {
    signal(SIGPIPE,SIG_IGN);
    orig_stat = (int(*)(const char*,struct stat*))dlsym(RTLD_DEFAULT,"stat");
    orig_access = (int(*)(const char*,int))dlsym(RTLD_DEFAULT,"access");
    orig_sysctl = (int(*)(int*,u_int,void*,size_t*,void*,size_t))dlsym(RTLD_DEFAULT,"sysctl");
    orig_getaddrinfo = (int(*)(const char*,const char*,const struct addrinfo*,struct addrinfo**))dlsym(RTLD_DEFAULT,"getaddrinfo");
    orig_connect = (int(*)(int,const struct sockaddr*,socklen_t))dlsym(RTLD_DEFAULT,"connect");
    MSHookFunction(stat,hooked_stat,&orig_stat);
    MSHookFunction(access,hooked_access,&orig_access);
    MSHookFunction(sysctl,hooked_sysctl,&orig_sysctl);
    MSHookFunction(getaddrinfo,hooked_getaddrinfo,&orig_getaddrinfo);
    MSHookFunction(connect,hooked_connect,&orig_connect);
    Class u = objc_getClass("UIDevice");
    if(u) MSHookMessageEx(u,@selector(identifierForVendor),(IMP)&hooked_idfv,(IMP*)&orig_idfv);
    Class b = objc_getClass("NSBundle");
    if(b) MSHookMessageEx(b,@selector(bundleIdentifier),(IMP)&hooked_bid,(IMP*)&orig_bid);
}
