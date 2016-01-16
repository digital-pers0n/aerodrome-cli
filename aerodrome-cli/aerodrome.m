//
//  Aerodrome.m
//  aerodrome
//
//  Created by digital_person on 1/1/16.
//  Copyright © 2016 home. All rights reserved.
// Credits:
// Jonathan Levin -  http://newosxbook.com/articles/11208ellpA-II.html
// Comex - https://gist.github.com/comex/0c19c1b3fa569f549947

#import <Foundation/Foundation.h>
#import "Apple80211.h"
#import "Apple80211Err.h"
#import "apple80211_var.h"
#import "apple80211_ioctl.h"
#import "apple80211_wps.h"

#define  AERODROME_DEFAULT_CHANNEL 11

#define ANSI_COLOR_RED      "\x1b[31m"
#define ANSI_COLOR_RESET    "\x1b[0m"
#define BOLDBLACK           "\x1b[1m\x1b[1m"


boolean_t aerodrome_bind(const char *if_name, Apple80211Ref *ref_ptr)
{
    Apple80211Err   error;
    boolean_t       found = FALSE;
    CFStringRef     if_name_cf;
    Apple80211Ref   wref;
    
    
    error = Apple80211Open(&wref);
    if (error != kA11NoErr) {
        fprintf(stderr, "Apple80211Open failed: %x %s\n", error, Apple80211ErrToStr(error));
        return (FALSE);
    }
    
    if_name_cf = CFStringCreateWithCString(NULL, if_name, kCFStringEncodingASCII);
    
    error = Apple80211BindToInterface(wref, if_name_cf);
    CFRelease(if_name_cf);
    if (error == kA11NoErr) {
        *ref_ptr = (Apple80211Ref)wref;
        found = TRUE;
        fprintf(stderr, "Aerodrome: interface %s\n", if_name);
        
        
    }else{
        fprintf(stderr, "Apple80211BindToInterface %s failed: %x, %s\n", if_name, error, Apple80211ErrToStr(error));
        Apple80211Close(wref);
        *ref_ptr = NULL;
        return (FALSE);
        
    }
    
    
    return (found);
}

const char * aerodrome_auto_bind(Apple80211Ref *ref_ptr)
{
 
    long			count;
    Apple80211Err	error;
    CFArrayRef		if_name_list;
    const char *	ret_name = NULL;
    Apple80211Ref	wref;
    
    error = Apple80211Open(&wref);
    if (error != kA11NoErr) {
        fprintf(stderr, "Apple80211Open failed: %x %s\n", error, Apple80211ErrToStr(error));
        return (NULL);
    }
    error = Apple80211GetIfListCopy(wref, &if_name_list);
    if (error != kA11NoErr) {
        fprintf(stderr, "Apple80211GetIfListCopy failed: %x %s\n", error, Apple80211ErrToStr(error));
        goto done;
    }
    count = CFArrayGetCount(if_name_list);
    if (count > 0) {
        CFStringRef	if_name;
        
        if_name = CFArrayGetValueAtIndex(if_name_list, 0);
        //CFShow(if_name);
        error = Apple80211BindToInterface(wref, if_name);
        if (error != kA11NoErr) {
            fprintf(stderr, "Apple80211BindToInterface failed: %x %s\n",
                    error, Apple80211ErrToStr(error));
        } else {
            ret_name = CFStringGetCStringPtr(if_name, kCFStringEncodingASCII);
             
            }
    }
    
    
    
done:
    if (ret_name == NULL) {
        Apple80211Close(wref);
        *ref_ptr = NULL;
        
    }
    else {
        
        *ref_ptr = wref;
        g_if_name = (char *)ret_name;
        return (ret_name);
    }
    
    CFRelease(if_name_list);
    
    return (ret_name);
}

void aerodrome_close(Apple80211Ref ref)
{
    Apple80211Close(ref);
    return;
}

void aerodrome_disassociate(Apple80211Ref ref)
{
    Apple80211Err error;
    error = Apple80211Disassociate(ref);
    if (error != kA11NoErr){
        fprintf(stderr, "Disassociate failed: %x %s\n", error, Apple80211ErrToStr(error));
    }
    //printf("Disassociated\n");
    return;
}

boolean_t aerodrome_join_network(Apple80211Ref ref, char * network, char * pass)
{
    Apple80211Err               error;
    boolean_t                   ret = FALSE;
    CFStringRef                 key = NULL;
    CFStringRef                 ssid_str;
    CFMutableDictionaryRef      scan_args = NULL;
    CFArrayRef                  scan_result = NULL;
    
    
    if (pass != NULL) {
        
        key = CFStringCreateWithCString(kCFAllocatorDefault, pass, kCFStringEncodingASCII);
        
    } else {
        
        key = NULL;
    }
    
    ssid_str = CFStringCreateWithCString(kCFAllocatorDefault, network, kCFStringEncodingASCII);

    scan_args = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(scan_args, CFSTR("SSID_STR"), ssid_str);
    
    error = Apple80211Scan(ref, &scan_result, scan_args);
    
    CFRelease(scan_args);
    CFRelease(ssid_str);
    
    if (error != kA11NoErr) {
        fprintf(stderr, "Apple80211Scan failed: %d %s\n", error, Apple80211ErrToStr(error));
        
        if (key != NULL) {
            
            CFRelease(key);
        }
        return (FALSE);

    }
    
    if (CFArrayGetCount(scan_result) > 0){
        CFDictionaryRef scan_dict;
        scan_dict = CFArrayGetValueAtIndex(scan_result, 0);
        
        
        error = Apple80211Associate(ref, scan_dict, key);
        //CFShow(scan_dict);
        
        
        if(error != kA11NoErr) {
            
            fprintf(stderr, "Apple80211Associate failed: %d %s\n", error, Apple80211ErrToStr(error));
            
            if (key != NULL) {
                
                CFRelease(key);
            }
            
            return (FALSE);
            
        } else {
            
            ret = TRUE;
            //CFShow(scan_dict);
        }
    }
    if (scan_result != NULL){
        
        CFRelease(scan_result);
    }
    
    if (key != NULL) {
        
        CFRelease(key);
    }
    //fprintf(stderr, "%i err\n", error);
    return  (ret);

}

boolean_t aerodrome_power_cycle(Apple80211Ref ref)
{
    uint32_t power = 0;
    Apple80211GetPower(ref, &power);
    if (power > 0) {
        Apple80211SetPower(ref, 0);
        printf("Aerodrome: power off\n");
        return FALSE;
    } else if (power == 0) {
        Apple80211SetPower(ref, 1);
        printf("Aerodrome: power on\n");
        return TRUE;
    }
    return power;
}

boolean_t aerodrome_ibss_create(Apple80211Ref ref, const char * network, int channel)
{
    int default_channel = AERODROME_DEFAULT_CHANNEL;
    if (channel > 0) {
        default_channel = channel;
    }
    
    Apple80211Err error;
    CFStringRef Keys[10];
    void *Values[10];
    CFStringRef ssid =  CFStringCreateWithCString(kCFAllocatorDefault, network, kCFStringEncodingUTF8);
    
    int auth_low = APPLE80211_AUTHTYPE_OPEN,
    auth_up = APPLE80211_AUTHTYPE_NONE,
    chan = default_channel,
    chan_flag = 138,
    ciph = APPLE80211_CIPHER_NONE,
    phy_mode = APPLE80211_MODE_AUTO;
    
    Keys[0] = CFSTR("AP_MODE_AUTH_LOWER");  Values[0] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &auth_low);
    Keys[1] = CFSTR("AP_MODE_AUTH_UPPER");  Values[1] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &auth_up);
    Keys[2] = CFSTR("CHANNEL");             Values[2] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &chan);
    Keys[3] = CFSTR("CHANNEL_FLAGS");       Values[3] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &chan_flag);
    Keys[4] = CFSTR("AP_MODE_CYPHER_TYPE"); Values[4] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &ciph);
    Keys[5] = CFSTR("SSID");                Values[5] = (void *)ssid;
    Keys[6]= CFSTR("AP_MODE_PHY_MODE");     Values[6] = (void *)CFNumberCreate(kCFAllocatorDefault, 9, &phy_mode);
    
    Keys[7] = CFSTR("AP_MODE_SSID_BYTES");  Values[7] = (void *)CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)network, strlen(network), kCFAllocatorNull);
    Keys[8] = CFSTR("AP_MODE_KEY");         Values[8] = (void *)CFSTR("1234567890");
    Keys[9] = CFSTR("AP_MODE_IE_LIST");     Values[9] = (void *)CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)network, strlen(network), kCFAllocatorNull);
    
    CFDictionaryRef ibssmode_dict = CFDictionaryCreate(kCFAllocatorDefault,
                                                       (void *)&Keys,
                                                       (void *)&Values,
                                                       10,
                                                       &kCFTypeDictionaryKeyCallBacks,
                                                       &kCFTypeDictionaryValueCallBacks);
    
    
    error = Apple80211Set(ref, APPLE80211_IOC_IBSS_MODE, 1, ibssmode_dict);
    if (error != kA11NoErr) {
        printf("Failed to create network: %i %s\n", error, Apple80211ErrToStr(error));
        CFRelease(ibssmode_dict);
        
        return (FALSE);
    }
    
    
    CFRelease(ibssmode_dict);
    return (TRUE);
}


boolean_t aerodrome_scan(Apple80211Ref ref)
{
    int             i;
    long            count;
    int             rssi, channel, noise;
    char            *security;
    Apple80211Err   error;
    CFArrayRef      scan_result;
    CFStringRef     SSID, BSSID;
    CFDictionaryRef buffer;
    
//    CFMutableDictionaryRef dict;
//    
//    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//    
    
    
    //CFDictionaryAddValue(dict, CFSTR("SCAN_SSID_LIST"), CFSTR("net name"));
    
    error = Apple80211Scan(ref, &scan_result, NULL);
    if (error != kA11NoErr) {
        printf("Scan failed: %i %s\n", error, Apple80211ErrToStr(error));
        return (FALSE);
    }
    
    count = CFArrayGetCount(scan_result);
    
    if (count == 0) {
        printf("no networks\n");
        return (TRUE);
    }
    
    
    
    
    printf(BOLDBLACK "\nSSID:                BSSID:             RSSI: NOISE:  CH: SEC:\n" ANSI_COLOR_RESET);
    
    for (i = 0; i < count; i++) {
        buffer = CFArrayGetValueAtIndex(scan_result, i);
        SSID     = CFDictionaryGetValue(buffer, @"SSID_STR");
        BSSID    = CFDictionaryGetValue(buffer, @"BSSID");
        
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(buffer, @"RSSI"), kCFNumberIntType, &rssi);
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(buffer, @"NOISE"), kCFNumberIntType, &noise);
        CFNumberGetValue((CFNumberRef)CFDictionaryGetValue(buffer, @"CHANNEL"), kCFNumberIntType, &channel);
        
        if (CFDictionaryContainsKey(buffer, @"WPA_IE")) {
            security = "WPA";
        } else if (CFDictionaryContainsKey(buffer, @"WEP")) {
            security = "WEP";
        } else if (CFDictionaryContainsKey(buffer, @"RSN_IE")){
            security = "WPA2";
            
        } else {
            
            security = "Open";
        }
        
        
        printf("%-18s  %18s  %5i  %5i  %3i %-5s\n",
               CFStringGetCStringPtr(SSID, kCFStringEncodingASCII),
               CFStringGetCStringPtr(BSSID, kCFStringEncodingASCII),
               rssi,
               noise,
               channel,
               security
               );
        
    }
    printf("\n");
    CFRelease(scan_result);
    
    return (TRUE);
}

boolean_t aerodrome_dump_rom(Apple80211Ref ref)
{
    CFDataRef data = NULL;
    SInt32 error;
    int rc;
    char *s = "/tmp/wireless_rom";
    CFURLRef path = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)s, strlen(s), 0);
    
    rc = Apple80211CopyValue(ref, APPLE80211_IOC_ROM, 0, &data);
    
    if (rc != kA11NoErr) {
        printf("Dump failed: %i %s\n", rc, Apple80211ErrToStr(rc));
        CFRelease(path);
        return (FALSE);
    }
    CFURLWriteDataAndPropertiesToResource(path, data, NULL, &error);
    if (error > 0) {
        printf("write error: %s %i\n", s, error);
        CFRelease(path);
        return (FALSE);
    }
    printf("rom dumped to file: %s\n", s);
    CFRelease(path);
    return (TRUE);
}






















