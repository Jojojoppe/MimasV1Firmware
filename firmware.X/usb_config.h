#ifndef USBCFG_H
#define USBCFG_H

#include <stdint.h>

#define USB_EP0_BUFF_SIZE		8	// Valid Options: 8, 16, 32, or 64 bytes.
#define USB_MAX_NUM_INT     	1   //Set this number to match the maximum interface number used in the descriptors for this firmware project
#define USB_MAX_EP_NUMBER	    1   //Set this number to match the maximum endpoint number used in the descriptors for this firmware project

#define USB_NUM_STRING_DESCRIPTORS 3  //Set this number to match the total number of string descriptors that are implemented in the usb_descriptors.c file

#define USB_USER_DEVICE_DESCRIPTOR &device_dsc
#define USB_USER_DEVICE_DESCRIPTOR_INCLUDE extern const USB_DEVICE_DESCRIPTOR device_dsc

#define USB_USER_CONFIG_DESCRIPTOR USB_CD_Ptr
#define USB_USER_CONFIG_DESCRIPTOR_INCLUDE extern const uint8_t *const USB_CD_Ptr[]

//#define USB_PING_PONG_MODE USB_PING_PONG__NO_PING_PONG    //Not recommended
#define USB_PING_PONG_MODE USB_PING_PONG__FULL_PING_PONG    //A good all around setting
//#define USB_PING_PONG_MODE USB_PING_PONG__EP0_OUT_ONLY    //Another good setting
//#define USB_PING_PONG_MODE USB_PING_PONG__ALL_BUT_EP0	    //Not recommended

//#define USB_POLLING
#define USB_INTERRUPT

#define USB_PULLUP_OPTION USB_PULLUP_ENABLE
//#define USB_PULLUP_OPTION USB_PULLUP_DISABLED

#define USB_TRANSCEIVER_OPTION USB_INTERNAL_TRANSCEIVER
//#define USB_TRANSCEIVER_OPTION USB_EXTERNAL_TRANSCEIVER

#define USB_SPEED_OPTION USB_FULL_SPEED
//#define USB_SPEED_OPTION USB_LOW_SPEED //(this mode is only supported on some microcontrollers)

#define USB_ENABLE_STATUS_STAGE_TIMEOUTS    //Comment this out to disable this feature.
#define USB_STATUS_STAGE_TIMEOUT     (uint8_t)45

#define IMPLEMENT_MICROSOFT_OS_DESCRIPTOR
#if defined(IMPLEMENT_MICROSOFT_OS_DESCRIPTOR)
    #if defined(__XC8)
        #define __attribute__(a)
    #endif
    #define MICROSOFT_OS_DESCRIPTOR_INDEX   (unsigned char)0xEE //Magic string index number for the Microsoft OS descriptor
    #define GET_MS_DESCRIPTOR               (unsigned char)0xEE //(arbitarily assigned, but should not clobber/overlap normal bRequests)
    #define EXTENDED_COMPAT_ID              (uint16_t)0x0004
    #define EXTENDED_PROPERTIES             (uint16_t)0x0005

    typedef struct __attribute__ ((packed)) _MS_OS_DESCRIPTOR
    {
        uint8_t bLength;
        uint8_t bDscType;
        uint16_t string[7];
        uint8_t vendorCode;
        uint8_t bPad;
    }MS_OS_DESCRIPTOR;

    typedef struct __attribute__ ((packed)) _MS_COMPAT_ID_FEATURE_DESC
    {
        uint32_t dwLength;
        uint16_t bcdVersion;
        uint16_t wIndex;
        uint8_t bCount;
        uint8_t Reserved[7];
        uint8_t bFirstInterfaceNumber;
        uint8_t Reserved1;
        uint8_t compatID[8];
        uint8_t subCompatID[8];
        uint8_t Reserved2[6];
    }MS_COMPAT_ID_FEATURE_DESC;

    typedef struct __attribute__ ((packed)) _MS_EXT_PROPERTY_FEATURE_DESC
    {
        uint32_t dwLength;
        uint16_t bcdVersion;
        uint16_t wIndex;
        uint16_t wCount;
        uint32_t dwSize;
        uint32_t dwPropertyDataType;
        uint16_t wPropertyNameLength;
        uint16_t bPropertyName[20];
        uint32_t dwPropertyDataLength;
        uint16_t bPropertyData[39];
    }MS_EXT_PROPERTY_FEATURE_DESC;
    
    extern const MS_OS_DESCRIPTOR MSOSDescriptor;
    extern const MS_COMPAT_ID_FEATURE_DESC CompatIDFeatureDescriptor;
    extern const MS_EXT_PROPERTY_FEATURE_DESC ExtPropertyFeatureDescriptor;
#endif

#define USB_SUPPORT_DEVICE

// ENDPOINT SETTINGS
// -----------------

#define USB_USE_GEN
#define USBGEN_EP_SIZE          64
#define USBGEN_EP_NUM            1

#endif