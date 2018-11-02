//
//  main.m
//  aerodrome-cli
//
//  Created by digital_person on 1/1/16.
//  Copyright © 2016 home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "aerodrome.h"

#define APP_VERSION 0.3


void
usage()
{
    fprintf(stderr,
            "\naerodrome %.1f\n"
            "[ -i <ifname> ] -d -p -I -D -w | -s scan | -a <ibbs>\n"
            "-n <ssid> | -k <pass> | -c <chan> | -l <locale code>\n\n"
            
            "-i      interface name (en0, en1 etc.)\n"
            "-I      network information\n"
            "-d      disconnect from current network\n"
            "-p      switch power on/off\n"
            "-s      scan for networks\n"
            "-a      start computer-to-computer network with name\n"
            "-c      set channel for computer-to-computer network (default 11)\n"
            "-n      associate to wireless network\n"
            "-k      password for wireless network (if needed)\n"
            "-l      set locale code (1 2 3 4 5 6)\n"
            "-w      show hardware info\n"
            "-D      dump rom into /tmp/wireless_rom\n"
            "-T      show supported transmisson rates\n"
            "-t      set transmission rate\n"
            "-P      set powersave mode (1 2 7 8)\n"
            "-X      set txPower\n\n"
            
            "example: aerodrome -i en1 -n iPhone -k passkey2265\n\n", APP_VERSION);
}

int main(int argc, char * argv[]) {
    
    int             ch;
    int             channel = 0;
    boolean_t		disassociate = FALSE;
    boolean_t       info = FALSE;
    const char *	if_name = NULL;
    const char *	pass = NULL;
    const char *	network = NULL;
    const char *    ibss = NULL;
    boolean_t       power = FALSE;
    boolean_t       scan = FALSE;
    Apple80211Ref   ref = NULL;
    boolean_t       test = FALSE;
    uint32_t        locale = 0;
    boolean_t       dump_rom = FALSE;
    boolean_t       hw_info = FALSE;
    boolean_t       rate = FALSE;
    uint32_t        setrate = 0;
    uint32_t        set_powersave = 0;
    uint32_t        set_tx = 0;
    
    if (argc < 2) {
        usage();
        
    }
    while ((ch =  getopt(argc, argv, "DdpwshHITi:a:n:k:c:l:t:P:X:")) != EOF) {
        switch ((char)ch) {
            case 'h':
            case 'H':
                usage();
                exit(0);
                break;
            case 'n':		/* join network */
                network = optarg;
                break;
            case 's':		/* scan for wireless netork */
                scan = TRUE;
                break;
            case 'd':
                disassociate = TRUE;
                break;
            case 'i':		/* specify the interface */
                if_name = optarg;
                break;
            case 'p':		/* switch power */
                power = TRUE;
                break;
            case 'k':		/* specify the password for associate */
                pass = optarg;
                break;
            case 'a':		/* specify the IBSS name */
                ibss = optarg;
                break;
            case 'c':		/* set channel */
                channel = atoi(optarg);
                break;
            case 'I':
                info = TRUE;
                break;
            case 'l':
                locale = atoi(optarg);
                break;
            case 'D':
                dump_rom = TRUE;
                break;
            case 'w':
                hw_info = TRUE;
                break;
            case 'T':
                rate = TRUE;
                break;
            case 't':
                setrate = atoi(optarg);
                break;
            case 'P':
                set_powersave = atoi(optarg);
                break;
            case 'X':
                set_tx = atoi(optarg);
                break;
            default:
                break;
        }
    }
    
    // Bind to interface
    if (if_name != NULL)
    {
        strncpy(g_if_name, if_name, IF_NAMESIZE);
        if (aerodrome_bind(if_name, &ref) == FALSE)
        {
            fprintf(stderr, "Interface '%s' is not present or not AirPort\n",
                    if_name);
            exit(EXIT_FAILURE);
        }
    } else {
        if (!aerodrome_auto_bind(&ref)) {
            fputs("Invalid interface\n", stderr);
            exit(EXIT_FAILURE);
        }
    }
    
    
    // Associate with network
    
    if (network != NULL) {
        
        fprintf(stderr, "attempting to join network '%s'... ", network);
        
        if (aerodrome_join_network(ref, network, pass)) {
            puts("Done.");
        }
    }
    
    
    // Create computer-to-computer network
    
    if (ibss != NULL) {
        
        fprintf(stderr, "attempting to create network '%s'... ", ibss);
        
        if(aerodrome_ibss_create(ref, ibss, channel)){
            puts("Done.");
        }
    }
    
    // Switch power on/off
    
    if (power) {
        power_cycle();
    }
    
    
    // Disassociate from current network
    if (disassociate) {
        aerodrome_disassociate(ref);
    }
    
    if (info) {
        get_info();
    }
    
    if (scan) {
        aerodrome_scan(ref);
    }
    
    if (test) {
        // aerodrome_test(ref);
    }
    
    if (locale > 0) {
        set_locale(locale);
        printf("Locale: %s \n", get_locale());
    }
    
    if (dump_rom) {
        aerodrome_dump_rom(ref);
    }
    
    if (hw_info) {
        get_hardware_info();
    }
    
    if (rate) {
        get_supported_rate();
    }
    
    if (setrate > 0) {
        
        set_rate(setrate);
        printf("txRate: %i Mbps\n", get_rate());
        
    }
    
    if (set_powersave > 0) {
        
        char * mode;
        
        set_powersave_mode(set_powersave);
        get_powersave_mode(&mode);
        printf("Powersave Mode: %s\n", mode);
    }
    
    if (set_tx > 0) {
        set_txpower(set_tx);
        printf("txPower: %i mW\n", get_txpower());
    }
    
    if (ref !=  NULL) {
        aerodrome_close(ref);
    }
    return 0;
}
