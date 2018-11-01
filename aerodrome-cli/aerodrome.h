//
//  Aerodrome.h
//  aerodrome
//
//  Created by digital_person on 1/1/16.
//  Copyright © 2016 home. All rights reserved.
//

#ifndef Aerodrome_h
#define Aerodrome_h
#import "Apple80211.h"
#import "Apple80211Err.h"
#import "apple80211_var.h"
#import "apple80211_ioctl.h"
#import "apple80211_wps.h"

// apple80211

boolean_t       aerodrome_bind(const char *if_name, Apple80211Ref *ref_ptr);

boolean_t       aerodrome_auto_bind(Apple80211Ref *ref_ptr);

void            aerodrome_close(Apple80211Ref ref);

void            aerodrome_disassociate(Apple80211Ref ref);

boolean_t       aerodrome_join_network(Apple80211Ref ref, const char * network, const char * pass);

boolean_t       aerodrome_ibss_create(Apple80211Ref ref, const char * network, int channel);

boolean_t       aerodrome_power_cycle(Apple80211Ref ref);

boolean_t       aerodrome_scan(Apple80211Ref ref);

boolean_t       aerodrome_dump_rom(Apple80211Ref ref);


// ioctl

char *  get_locale();

int     set_locale(uint32_t locale);

int     get_ssid(char *ssid);

int     get_bssid(struct ether_addr *bssid);

int     get_txpower();

int     set_txpower(uint32_t power);

char *  get_state();

char *  get_opmode();

char *  get_phymode();

char *  get_cipher();

int     get_rate();

int     set_rate(uint32_t rate);

int     get_supported_rate();

int     get_rssi();

int     get_noise();

int     get_auth(char *auth[]);

int     get_channels_num();

int     get_channel(struct apple80211_channel *chan);

int     get_powersave_mode(char *val[]);

void    set_powersave_mode(uint32_t value);

void    get_driver_version();

int     multiple_scan();

void    get_hardware_info();

void    get_info();

bool    power_cycle();

void    get_transfer_stats();

int     get_mcs_index();

int     set_mcs_index(uint32_t mcs);

char    *get_ap_mode();

int     set_ap_mode(uint32_t ap_mode);

/**
 @param cc must contain enough space to hold APPLE80211_MAX_CC_LEN number of characters
 */
void    get_country_code(char *cc);
/**
 @param cc must contain enough space to hold APPLE80211_MAX_CC_LEN number of characters
 */
void    set_country_code(char *cc);

#endif /* Aerodrome_h */
