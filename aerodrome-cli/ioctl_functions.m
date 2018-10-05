//
//  ioctl_functions.m
//  aerodrome
//
//  Created by digital_person on 1/1/16.
//  Copyright © 2016 home. All rights reserved.
// Credits:
// Jonathan Levin -  http://newosxbook.com/articles/11208ellpA-II.html
// Comex - https://gist.github.com/comex/0c19c1b3fa569f549947

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <sys/ioctl.h>


#import "Apple80211.h"
#import "Apple80211Err.h"
#import "apple80211_var.h"
#import "apple80211_ioctl.h"
#import "apple80211_wps.h"

char * g_if_name;

struct apple80211_scan_multiple_data {
    uint32_t version; // 0
    uint32_t three; // 4
    uint32_t ssid_count; // 8
    struct apple80211_ssid_data ssids[16]; // c
    uint32_t bssid_count;
    struct ether_addr bssids[16];
    uint32_t scan_type; // 2f0
    uint32_t phy_mode; // 2f4
    uint16_t dwell_time; // 2f8
    uint32_t rest_time; // 2fc
    uint32_t channel_count; // 300
    struct apple80211_channel channels[128]; // 304
    uint8_t unk2[1]; // 904
};

int a80211_getset(uint32_t ioc, uint32_t type, uint32_t *valuep, void *data, size_t length)
{
    struct apple80211req cmd;
    
    int a80211_sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (a80211_sock == -1) {
        return -1;
    }
    
    bzero(&cmd, sizeof(cmd));
    
    // memcpy(cmd.req_if_name, g_if_name, 16);
    strlcpy(cmd.req_if_name, g_if_name, sizeof(cmd.req_if_name));
    cmd.req_type = type;
    cmd.req_val = valuep ? *valuep : 0;
    cmd.req_len = (uint32_t) length;
    cmd.req_data = data;
    errno = 0;
    int ret = ioctl(a80211_sock, ioc, &cmd, sizeof(cmd));
    

    if (ret < 0) {
        
        //perror("");
        //printf("req_type: %i\n", type);
        
    }

    
    if (valuep)
        *valuep = cmd.req_val;
        
        close(a80211_sock);
        return ret;
}

int get_channel(struct apple80211_channel *chan)
{
    struct apple80211_channel_data data;
    int ret;
    
    if ((ret = a80211_getset(SIOCGA80211, APPLE80211_IOC_CHANNEL, 0, &data, sizeof(data))))
        return ret;
    //ensure(data.version == 1);
    *chan = data.channel;
    return 0;
}

int set_locale(uint32_t locale)
{
    return a80211_getset(SIOCSA80211, 28, &locale, NULL, 0);
}

char *get_locale()
{
    
    uint32_t locale_code = 0;
    static char *locale = "UNKNOWN";
    static char *lc[7] =
    {
        "UNKNOWN",
        "X0 (FCC)",
        "X3 (ETSI)",
        "JP (JAPAN)",
        "KOREA",
        "X1 (APAC)",
        "X2 (ROW)"
    };
    
    a80211_getset(SIOCGA80211, 28, &locale_code, NULL, 0);
    if (locale_code == APPLE80211_LOCALE_UNKNOWN) {
        locale = lc[0];
    } else if (locale_code == APPLE80211_LOCALE_FCC){
        locale = lc[1];
    } else if (locale_code == APPLE80211_LOCALE_ETSI){
        locale = lc[2];
    } else if (locale_code == APPLE80211_LOCALE_JAPAN){
        locale = lc[3];
    } else if (locale_code == APPLE80211_LOCALE_KOREA){
        locale = lc[4];
    } else if (locale_code == APPLE80211_LOCALE_APAC){
        locale = lc[5];
    } else if (locale_code == APPLE80211_LOCALE_ROW){
        locale = lc[6];
    }
    
    return (locale);
    
    
}

int get_ssid(char *ssid)
{
    return a80211_getset(SIOCGA80211, APPLE80211_IOC_SSID, 0, ssid, 32);
}

int get_bssid(struct ether_addr *bssid)
{
    return a80211_getset(SIOCGA80211, APPLE80211_IOC_BSSID, 0, bssid, sizeof(*bssid));
}

int get_txpower()
{
    uint32_t pwr = 0;
    a80211_getset(SIOCGA80211, APPLE80211_IOC_TXPOWER, &pwr, NULL, 0);
    return pwr;
}

int set_txpower(uint32_t power)
{
    return a80211_getset(SIOCSA80211, APPLE80211_IOC_TXPOWER, &power, NULL, 0);
}

char * get_state()
{
    char *ret = "unknown";
    char *states[5] =
    {
        "default",
        "scanning",
        "authenticating",
        "associating",
        "running"
    };
    
    uint32_t st = 0;
    a80211_getset(SIOCGA80211, APPLE80211_IOC_STATE, &st, NULL, 0);
    
    if (st == APPLE80211_S_INIT) {
        ret = states[0];
    } else if (st == APPLE80211_S_SCAN){
        ret = states[1];
    } else if (st == APPLE80211_S_AUTH){
        ret = states[2];
    } else if (st == APPLE80211_S_ASSOC){
        ret = states[3];
    } else if (st == APPLE80211_S_RUN){
        ret = states[4];
    }
    
    
    return (ret);
    
}

char * get_opmode()
{
    char *ret = "none";
    
    char *modes[6] =
    {
        "none",
        "Infrastructure station",
        "IBSS (adhoc) station",
        "Old lucent compatible adhoc demo",
        "Software Access Point",
        "Monitor mode"
    };
    
    uint32_t op = 0;
    a80211_getset(SIOCGA80211, APPLE80211_IOC_OP_MODE, &op, NULL, 0);
    
    if (op == APPLE80211_M_NONE) {
        ret = modes[0];
    } else if (op == APPLE80211_M_STA) {
        ret = modes[1];
    } else if (op == APPLE80211_M_IBSS) {
        ret = modes[2];
    } else if (op == APPLE80211_M_AHDEMO) {
        ret = modes[3];
    } else if (op == APPLE80211_M_HOSTAP) {
        ret = modes[4];
    } else if (op == APPLE80211_M_MONITOR) {
        ret = modes[5];
    }
    
    
    
    return (ret);
}

int APPLE80211_MODE_11AC = 0x80;

char * get_phymode()
{
    
    char *modes[9] =
    {
        "unknown",
        "auto",
        "802.11a",
        "802.11b",
        "802.11g",
        "802.11n",
        "turbo a",
        "turbo g",
        "802.11ac"
    };
    
    //uint32_t phy;
    struct apple80211_phymode_data phy;
    
    memset(&phy, 0, sizeof(phy));
    a80211_getset(SIOCGA80211, APPLE80211_IOC_PHY_MODE, 0, &phy, sizeof(phy));
    
    //a80211_getset(SIOCGA80211, APPLE80211_IOC_PHY_MODE, &phy, NULL, 0);
    
    
    
    if (phy.active_phy_mode == APPLE80211_MODE_UNKNOWN) {
        return (modes[0]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_AUTO) {
        return (modes[1]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_11A) {
        return (modes[2]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_11B) {
        return (modes[3]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_11G) {
        return (modes[4]);
    }  else if (phy.active_phy_mode  == APPLE80211_MODE_11N) {
        return (modes[5]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_TURBO_A) {
        return (modes[6]);
    } else if (phy.active_phy_mode  == APPLE80211_MODE_TURBO_G) {
        return (modes[7]);
    } else if (phy.active_phy_mode == APPLE80211_MODE_11AC) {
        return (modes[8]);
    }
    return (modes[0]);
}

char *get_cipher()
{
    char *modes[8] = {"none", "WEP 40", "WEP 104", "TKIP", "AES (OCB)", "AES (CCM)", "PMK", "PMKSA"};
    //uint32_t mode;
    
    struct apple80211_key mode;
    memset(&mode, 0, sizeof(mode));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_CIPHER_KEY, 0, &mode, sizeof(mode));
    
    
    //a80211_getset(SIOCGA80211, APPLE80211_IOC_CIPHER_KEY, &mode, NULL, 0);
    
    if (mode.key_cipher_type == APPLE80211_CIPHER_NONE) {
        return (modes[0]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_WEP_40) {
        return (modes[1]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_WEP_104) {
        return (modes[2]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_TKIP) {
        return (modes[3]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_AES_OCB) {
        return (modes[4]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_AES_CCM) {
        return (modes[5]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_PMK) {
        return (modes[6]);
    } else if (mode.key_cipher_type == APPLE80211_CIPHER_PMKSA) {
        return (modes[7]);
    }
    
    
    
    return (modes[0]);
}

int get_rate()
{
    uint32_t rate = 0;
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_RATE, &rate, NULL, 0);
    
    return rate;
}

int set_rate(uint32_t rate)
{
    return a80211_getset(SIOCSA80211, APPLE80211_IOC_RATE, &rate, NULL, 0);
}

int get_supported_rate()
{
 
    int rates = 0;
    struct apple80211_rate_set_data data;
    memset(&data, 0, sizeof(data));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_RATE_SET, 0, &data, sizeof(data));
    
    printf("Supported rates (Mbps): ");
    
    for (int i = 0; i < APPLE80211_MAX_RATES; i++) {
        if (data.rates[i].rate == 0) {
            ;
        } else {
            printf("%i ",  data.rates[i].rate);
        }
    }
    printf(" \n");
    
    return rates = data.num_rates;
}

int get_rssi()
{
    int32_t rssi = 0;
    
    struct apple80211_rssi_data data;
    
    memset(&data, 0, sizeof(data));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_RSSI, 0, &data, sizeof(data));
    
    if (data.rssi[0] > 0) {
        return rssi;
    }
    
    rssi = data.rssi[0];
    
    
    
    
    return rssi;
}

int get_noise()
{
    int32_t noise = 0;
    
    
    struct apple80211_noise_data ns;
    memset(&ns, 0, sizeof(ns));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_NOISE, 0, &ns, sizeof(ns));
    
    if (ns.noise[0] > 0) {
        return noise;
    }
    
    noise = ns.noise[0];
    
    return noise;
}



int multiple_scan()


{

    char *net = "test";
    
    struct apple80211_channel ch;
    memset(&ch, 0, sizeof(ch));
    
    ch.version = 1;
    ch.channel = 5;
    ch.flags   = APPLE80211_C_FLAG_IBSS | APPLE80211_C_FLAG_HOST_AP | APPLE80211_C_FLAG_10MHZ | APPLE80211_C_FLAG_2GHZ;
    
    struct apple80211_channel_data chd;
    
    struct apple80211_network_data dta;
    
    memset(&dta, 0, sizeof(dta));
    
    dta.version = 1;
    dta.nd_ssid_len = strlen(net);
    strncpy((char *)dta.nd_ssid, net, APPLE80211_MAX_SSID_LEN );
    dta.nd_auth_lower = APPLE80211_AUTHTYPE_OPEN;
    dta.nd_auth_upper = APPLE80211_AUTHTYPE_NONE;
    dta.nd_mode = APPLE80211_MODE_AUTO;
    dta.nd_channel = ch;
    dta.nd_ie_data = NULL;
    
    struct apple80211_key key;
    memset(&key, 0, sizeof(key));
    
    uint32_t val = 1;
    
    ch.flags = 138;
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_CHANNEL, 0, &chd, sizeof(chd));
    
    chd.channel.channel = 5;
    
    dta.nd_channel = chd.channel;
//
//    struct apple80211req cmd;
//    
//    int a80211_sock = socket(AF_INET, SOCK_DGRAM, 0);
//    if (a80211_sock == -1) {
//        return -1;
//    }
//    
//    bzero(&cmd, sizeof(cmd));
//    
//    struct apple80211_country_code_data cc;
//    memset(&cc, 0, sizeof(cc));
//    
//    char * ccc[3];
//    
//    //strlcpy((char *)cc.cc, ccc, sizeof(cc.cc));
//    
//    // memcpy(cmd.req_if_name, g_if_name, 16);
//    strlcpy(cmd.req_if_name, g_if_name, sizeof(cmd.req_if_name));
//    cmd.req_type = APPLE80211_IOC_POWERSAVE;
//    cmd.req_val = 1;
//    cmd.req_len = 0;
//    cmd.req_data = NULL;
//    
//
//    errno = 0;
//    int ret = ioctl(a80211_sock, SIOCSA80211, cmd);
//    if (ret < 0) {
//        perror("SIOCGA80211");
//        
//    }
//    
//    printf("%s\n", (char *)ccc);
//    
//    
//    
//    
//    close(a80211_sock);
    
    char * test[3];
    
    bzero(&test, sizeof(test));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_COUNTRY_CODE, 0, &test, sizeof(test));
    
    
    
    printf("%s\n", test);
    
    
    
    return 1;
}





int get_auth(char *auth[])
{
    int ret;
    
    char *auth_lower[3]    =
    {
        "Open",
        "Shared",
        "CISCO"
    };
    
    char *auth_upper[8] =
    {
        "None",
        "WPA",
        "WPA PSK",
        "WPA2",
        "WPA2 PSK",
        "LEAP",
        "802.1X",
        "WPS"
    };
    
    struct apple80211_authtype_data ath;
    
    memset(&ath, 0, sizeof(ath));
    
    ret = a80211_getset(SIOCGA80211, APPLE80211_IOC_AUTH_TYPE, 0, &ath, sizeof(ath));
    
    
    
    if (ath.authtype_lower == APPLE80211_AUTHTYPE_OPEN) {
        auth[0] = auth_lower[0];
    } else if (ath.authtype_lower == APPLE80211_AUTHTYPE_SHARED) {
        auth[0] = auth_lower[1];
    } else if (ath.authtype_lower == APPLE80211_AUTHTYPE_CISCO) {
        auth[0] = auth_lower[2];
    }
    
    if (ath.authtype_upper == APPLE80211_AUTHTYPE_NONE) {
        auth[1] = auth_upper[0];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_WPA) {
        auth[1] = auth_upper[1];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_WPA_PSK) {
        auth[1] = auth_upper[2];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_WPA2) {
        auth[1] = auth_upper[3];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_WPA2_PSK) {
        auth[1] = auth_upper[4];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_LEAP) {
        auth[1] = auth_upper[5];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_8021X) {
        auth[1] = auth_upper[6];
    } else if (ath.authtype_upper == APPLE80211_AUTHTYPE_WPS) {
        auth[1] = auth_upper[7];
    }
    
    return ret;
}

int get_channels_num()
{
    
    int channel = 0;
    struct apple80211_sup_channel_data data;
    memset(&data, 0, sizeof(data));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_SUPPORTED_CHANNELS, 0, &data, sizeof(data));
    
    printf("Supported channels: ");
    for (int i = 0; i < APPLE80211_MAX_CHANNELS ; i++) {
        if (data.supported_channels[i].channel == 0) {
            ;
        } else {
            printf("%i ",  data.supported_channels[i].channel);
        }
    }
    printf("\n");
    
    return channel = data.num_channels;
}



void get_driver_version()
{
    char version[64];
    memset(&version, 0, sizeof(version));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_DRIVER_VERSION, 0, &version, sizeof(version));
    
    printf("%s\n", version);
    
}

int get_powersave_mode(char *val[])
{
    uint32_t value = 0;
    
    char * modes[5] =
    {
        "Disabled",
        "80211",
        "Vendor Specific",
        "Throughput is maximized",
        "Power savings are maximized"
        
    };
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_POWERSAVE, &value, NULL, 0);
    
    if (value == APPLE80211_POWERSAVE_MODE_DISABLED) {
        val[0] = modes[0];
    } else if (value == APPLE80211_POWERSAVE_MODE_80211){
        val[0] = modes[1];
    } else if (value == APPLE80211_POWERSAVE_MODE_VENDOR){
        val[0] = modes[2];
    } else if (value == APPLE80211_POWERSAVE_MODE_MAX_THROUGHPUT){
        val[0] = modes[3];
    } else if (value == APPLE80211_POWERSAVE_MODE_MAX_POWERSAVE) {
        val[0] = modes[4];
    }
    
    return value;
    
}

void set_powersave_mode(uint32_t value)
{
    
    a80211_getset(SIOCSA80211, APPLE80211_IOC_POWERSAVE, &value, NULL, 0);
}

void get_hardware_info()
{
    char *powersave = NULL;
    
    get_powersave_mode(&powersave);
    
    char *buffer[32];
    //bzero(&buffer, sizeof(buffer));
    memset(&buffer, '\0', sizeof(buffer));
    a80211_getset(SIOCGA80211, APPLE80211_IOC_HARDWARE_VERSION, 0, &buffer, sizeof(buffer));
    
    
    
    
    printf("\nHardware info: ");
    get_driver_version();
    get_channels_num();
    printf("Powersave Mode: %s\n", powersave);
    printf("%s",  (char *)buffer);
    
    printf("\n");
    
}

void get_info()
{

    
    char *nm[32];
    memset(&nm, 0, sizeof(nm));
    get_ssid((char *)&nm);
    
    
    struct ether_addr addr;
    memset(&addr, 0, sizeof(addr));
    get_bssid(&addr);
    
    struct apple80211_channel chan;
    get_channel(&chan);
    
    char *locale    = get_locale();
    int tx          = get_txpower();
    char *state     = get_state();
    char *opmode    = get_opmode();
    char *phymode   = get_phymode();
    char *cipher    = get_cipher();
    char *driver[32];
    memset(&driver, 0, sizeof(driver));
    
    
    int rate = get_rate();
    int rssi = get_rssi();
    
    
    char *auth[2];
    get_auth(auth);
    
    printf("\n");
    
    printf("       SSID: %s\n"
           "      BSSID: %02x:%02x:%02x:%02x:%02x:%02x\n"
           "    Channel: %i\n"
           "     Locale: %s\n"
           "    txPower: %i mW\n"
           "      State: %s\n"
           "    Op mode: %s\n"
           "   Phy mode: %s\n"
           "       Rate: %i Mbps\n"
           "       RSSI: %i dBm\n"
           "      Noise: %i dBm\n"
           "802.11 auth: %s\n"
           "  link auth: %s\n"
           " key cipher: %s\n\n"
           ,
           (char *)nm,
           addr.octet[0], addr.octet[1], addr.octet[2], addr.octet[3], addr.octet[4], addr.octet[5],
           chan.channel,
           locale,
           tx,
           state,
           opmode,
           phymode,
           rate,
           rssi,
           get_noise(),
           auth[0],
           auth[1],
           cipher
           );
    
    
}
