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
        fprintf(stderr, "%s: %s\n", __func__, strerror(errno));
    }

    if (valuep) {
        *valuep = cmd.req_val;
    }
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
    a80211_getset(SIOCGA80211, 28, &locale_code, NULL, 0);
    
    switch (locale_code) {
        case APPLE80211_LOCALE_UNKNOWN:
            return "UNKNOWN";
            break;
        case APPLE80211_LOCALE_FCC:
            return "X0 (FCC)";
            break;
        case APPLE80211_LOCALE_ETSI:
            return "X3 (ETSI)";
            break;
        case APPLE80211_LOCALE_JAPAN:
            return "JP (JAPAN)";
            break;
        case APPLE80211_LOCALE_KOREA:
            return "KOREA";
            break;
        case APPLE80211_LOCALE_APAC:
            return "X1 (APAC)";
            break;
        case APPLE80211_LOCALE_ROW:
            return "X3 (ROW)";
            break;
            
        default:
            return "Unrecognized";
            break;
    }
    
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
    uint32_t st = 0;
    a80211_getset(SIOCGA80211, APPLE80211_IOC_STATE, &st, NULL, 0);
    
    switch (st) {
        case APPLE80211_S_INIT:
            return "default";
            break;
        case APPLE80211_S_SCAN:
            return "scanning";
            break;
        case APPLE80211_S_AUTH:
            return "authenticating";
            break;
        case APPLE80211_S_ASSOC:
            return "associating";
            break;
        case APPLE80211_S_RUN:
            return "running";
            break;
        default:
            return "unknown";
            break;
    }
}

char * get_opmode()
{
    uint32_t op = 0;
    a80211_getset(SIOCGA80211, APPLE80211_IOC_OP_MODE, &op, NULL, 0);
    
    switch (op) {
        case APPLE80211_M_NONE:
            return "none";
            break;
        case APPLE80211_M_STA:
            return "Infrastructure station";
            break;
        case APPLE80211_M_IBSS:
            return "IBSS (adhoc) station";
            break;
        case APPLE80211_M_AHDEMO:
            return "Old lucent compatible adhoc demo";
            break;
        case APPLE80211_M_HOSTAP:
            return "Software Access Point";
            break;
        case APPLE80211_M_MONITOR:
            return "Monitor Mode";
            break;
        default:
            return "Unknown Mode";
            break;
    }
}

static const int APPLE80211_MODE_11AC = 0x80;

char * get_phymode()
{
    struct apple80211_phymode_data phy;
    
    memset(&phy, 0, sizeof(phy));
    a80211_getset(SIOCGA80211, APPLE80211_IOC_PHY_MODE, 0, &phy, sizeof(phy));
    
    switch (phy.active_phy_mode) {
        case APPLE80211_MODE_UNKNOWN:
            return "Unknown";
            break;
        case APPLE80211_MODE_11A:
            return "802.11a : 5GHz, OFDM";
            break;
        case APPLE80211_MODE_11B:
            return "802.11b : 2GHz, CCK";
            break;
        case APPLE80211_MODE_11G:
            return "802.11g : 2GHz, OFDM";
            break;
        case APPLE80211_MODE_11N:
            return "802.11n : 2GHz/5Ghz, OFDM";
            break;
        case APPLE80211_MODE_TURBO_A:
            return "Turbo a : 5GHz, OFDM, 2x clock";
            break;
        case APPLE80211_MODE_TURBO_G:
            return "Turbo g : 2GHz, OFDM, 2x clock";
            break;
        case APPLE80211_MODE_11AC:
            return "802.11ac : 5GHz";
            break;
        case APPLE80211_MODE_AUTO:
            return "Auto";
            break;
        default:
            return "Unrecognized";
            break;
    }
}

char *get_cipher()
{
    struct apple80211_key mode;
    memset(&mode, 0, sizeof(mode));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_CIPHER_KEY, 0, &mode, sizeof(mode));
    
    switch (mode.key_cipher_type) {
        case APPLE80211_CIPHER_NONE:
            return "Open Network";
            break;
        case APPLE80211_CIPHER_WEP_40:
            return "40 bit WEP";
            break;
        case APPLE80211_CIPHER_WEP_104:
            return "104 bit WEP";
            break;
        case APPLE80211_CIPHER_TKIP:
            return "TKIP (WPA)";
            break;
        case APPLE80211_CIPHER_AES_OCB:
            return "AES (OCB)";
            break;
        case APPLE80211_CIPHER_AES_CCM:
            return "AES (CCM)";
            break;
        case APPLE80211_CIPHER_PMK:
            return "PMK";
            break;
        case APPLE80211_CIPHER_PMKSA:
            return "PMKSA";
            break;
        default:
            return "Unknown";
            break;
    }
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
        if (data.rates[i].rate != 0) {
            printf("%i ",  data.rates[i].rate);
        }
    }
    putchar('\n');
    
    return rates = data.num_rates;
}

int get_rssi()
{
    struct apple80211_rssi_data data;
    memset(&data, 0, sizeof(data));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_RSSI, 0, &data, sizeof(data));
    
    return data.rssi[0];
}

int get_noise()
{
    struct apple80211_noise_data ns;
    memset(&ns, 0, sizeof(ns));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_NOISE, 0, &ns, sizeof(ns));
    
    return ns.noise[0];
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


int get_auth(char **lower, char **upper) {
    struct apple80211_authtype_data data;
    memset(&data, 0, sizeof(data));
    int ret = a80211_getset(SIOCGA80211, APPLE80211_IOC_AUTH_TYPE, 0, &data, sizeof(data));
    switch (data.authtype_lower) {
        case APPLE80211_AUTHTYPE_OPEN:
            *lower = "Open";
            break;
        case APPLE80211_AUTHTYPE_SHARED:
            *lower = "Shared Key";
            break;
        case APPLE80211_AUTHTYPE_CISCO:
            *lower = "CISCO";
            break;
            
        default:
            *lower = "Unknown";
            break;
    }
    
    switch (data.authtype_upper) {
        case APPLE80211_AUTHTYPE_NONE:
            *upper = "None";
            break;
        case APPLE80211_AUTHTYPE_WPA:
            *upper = "WPA";
            break;
        case APPLE80211_AUTHTYPE_WPA_PSK:
            *upper = "WPA PSK";
            break;
        case APPLE80211_AUTHTYPE_WPA2:
            *upper = "WPA2";
            break;
        case APPLE80211_AUTHTYPE_WPA2_PSK:
            *upper = "WPA2 PSK";
            break;
        case APPLE80211_AUTHTYPE_LEAP:
            *upper = "LEAP";
            break;
        case APPLE80211_AUTHTYPE_8021X:
            *upper = "802.1x";
            break;
        case APPLE80211_AUTHTYPE_WPS:
            *upper = "WPS";
            break;
            
        default:
            *upper = "Unknown";
            break;
    }
    return ret;
}

int get_channels_num()
{
    struct apple80211_sup_channel_data data;
    memset(&data, 0, sizeof(data));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_SUPPORTED_CHANNELS, 0, &data, sizeof(data));
    
    uint32_t previous_channel = 0, channel = 0;
    printf("Supported channels: ");
    for (int i = 0; i < data.num_channels; i++) {
        channel = data.supported_channels[i].channel;
        if (channel == 0 || previous_channel > channel) {
            break;
        }
        printf("%i ", channel);
        previous_channel = channel;
    }
    putchar('\n');

    return data.num_channels;
}



void get_driver_version()
{
    char version[64];
    memset(&version, 0, sizeof(version));
    
    a80211_getset(SIOCGA80211, APPLE80211_IOC_DRIVER_VERSION, 0, &version, sizeof(version));
    
    printf("%s\n", version);
}

int get_powersave_mode(char **val)
{
    uint32_t value = 0;

    a80211_getset(SIOCGA80211, APPLE80211_IOC_POWERSAVE, &value, NULL, 0);
    
    switch (value) {
        case APPLE80211_POWERSAVE_MODE_DISABLED:
            *val = "Disabled";
            break;
        case APPLE80211_POWERSAVE_MODE_80211:
            *val = "80211";
            break;
        case APPLE80211_POWERSAVE_MODE_VENDOR:
            *val = "Vendor Specific";
            break;
        case APPLE80211_POWERSAVE_MODE_MIMO_STATIC:
            *val = "Mimo Static";
            break;
        case APPLE80211_POWERSAVE_MODE_MIMO_DYNAMIC:
            *val = "Mimo Dynamic";
            break;
        case APPLE80211_POWERSAVE_MODE_MIMO_MIMO:
            *val = "Mimo Mimo";
            break;
        case APPLE80211_POWERSAVE_MODE_WOW:
            *val = "WOW";
            break;
        case APPLE80211_POWERSAVE_MODE_MAX_THROUGHPUT:
            *val = "Throughput is maximized";
            break;
        case APPLE80211_POWERSAVE_MODE_MAX_POWERSAVE:
            *val = "Power savings are maximized";
            break;
            
        default:
            *val = "Unknown";
            break;
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
    
    char buffer[APPLE80211_MAX_VERSION_LEN * 2];
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
    char nm[APPLE80211_MAX_SSID_LEN];
    memset(nm, 0, sizeof(nm));
    get_ssid(nm);
    
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

    int rate = get_rate();
    int rssi = get_rssi();
    
    char *auth[2];
    get_auth(auth, auth + 1);
    
    putchar('\n');
    
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
