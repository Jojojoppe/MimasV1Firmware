#ifndef __USB_DESCRIPTORS_C
#define __USB_DESCRIPTORS_C

#include "usb.h"

const USB_DEVICE_DESCRIPTOR device_dsc = {
    0x12,                   // Size of this descriptor in bytes
    USB_DESCRIPTOR_DEVICE,  // DEVICE descriptor type
    0x0200,                 // USB Spec Release Number in BCD format
    0x00,                   // Class Code
    0x00,                   // Subclass code
    0x00,                   // Protocol code
    USB_EP0_BUFF_SIZE,      // Max packet size for EP0, see usb_config.h
    0x0000,                 // Vendor ID
    0x0001,                 // Product ID
    0x0000,                 // Device release number in BCD format
    0x01,                   // Manufacturer string index
    0x02,                   // Product string index
    0x00,                   // Device serial number string index
    0x01                    // Number of possible configurations
};

const uint8_t configDescriptor1[] = {
    0x09,                           // Size of this descriptor in bytes
    USB_DESCRIPTOR_CONFIGURATION,   // CONFIGURATION descriptor type
    32,0x00,                        // Total length of data for this cfg
    1,                              // Number of interfaces in this cfg
    1,                              // Index value of this configuration
    0,                              // Configuration string index
    _DEFAULT | _SELF,               // Attributes, see usb_device.h
    50,                             // Max power consumption (2X mA)
        
        0x09,                           // Size of this descriptor in bytes
        USB_DESCRIPTOR_INTERFACE,       // INTERFACE descriptor type
        0,                              // Interface Number
        0,                              // Alternate Setting Number
        2,                              // Number of endpoints in this intf
        0xFF,                           // Class code
        0xFF,                           // Subclass code
        0xFF,                           // Protocol code
        0,                              // Interface string index

            0x07,                           // Size of this descriptor in bytes
            USB_DESCRIPTOR_ENDPOINT,        // Endpoint Descriptor
            _EP01_OUT,                      // EndpointAddress
            _BULK,                          // Attributes
            USBGEN_EP_SIZE,0x00,            // size
            1,                              // Interval

            0x07,                           // Size of this descriptor in bytes
            USB_DESCRIPTOR_ENDPOINT,        // Endpoint Descriptor
            _EP01_IN,                       // EndpointAddress
            _BULK,                          // Attributes
            USBGEN_EP_SIZE,0x00,            // size
            1,                              // Interval
};


//Language code string descriptor
const struct{uint8_t bLength;uint8_t bDscType;uint16_t string[1];}sd000 = {
    sizeof(sd000),USB_DESCRIPTOR_STRING,{0x0409}
};

//Manufacturer string descriptor
const struct{uint8_t bLength;uint8_t bDscType;uint16_t string[8];}sd001 = {
    sizeof(sd001),USB_DESCRIPTOR_STRING,
    {
        'J','B','l','o','n','d','e','l'
    }
};

//Product string descriptor
const struct{uint8_t bLength;uint8_t bDscType;uint16_t string[8];}sd002 = {
    sizeof(sd002),USB_DESCRIPTOR_STRING,
    {
        'M','i','m','a','s',' ','V','1'
    }
};

//ROM struct{BYTE bLength;BYTE bDscType;WORD string[10];}sd003={
//sizeof(sd003),USB_DESCRIPTOR_STRING,
//{'0','1','2','3','4','5','6','7','8','9'}};

//Array of configuration descriptors
const uint8_t *const USB_CD_Ptr[]= {
    (const uint8_t *const)&configDescriptor1
};

//Array of string descriptors
const uint8_t *const USB_SD_Ptr[]= {
    (const uint8_t *const)&sd000,
    (const uint8_t *const)&sd001,
    (const uint8_t *const)&sd002
    //(const uint8_t *const)&sd003  //uncomment if implementing a serial number string descriptor named sd003
};

#if defined(IMPLEMENT_MICROSOFT_OS_DESCRIPTOR)
    const MS_OS_DESCRIPTOR MSOSDescriptor = {   
        sizeof(MSOSDescriptor),         //bLength - lenght of this descriptor in bytes
        USB_DESCRIPTOR_STRING,          //bDescriptorType - "string"
        {'M','S','F','T','1','0','0'},  //qwSignature - special values that specifies the OS descriptor spec version that this firmware implements
        GET_MS_DESCRIPTOR,              //bMS_VendorCode - defines the "GET_MS_DESCRIPTOR" bRequest literal value
        0x00                            //bPad - always 0x00
    };
    //Extended Compat ID OS Feature Descriptor
    const MS_COMPAT_ID_FEATURE_DESC CompatIDFeatureDescriptor =
    {
        //----------Header Section--------------
        sizeof(CompatIDFeatureDescriptor),  //dwLength
        0x0100,                             //bcdVersion = 1.00
        EXTENDED_COMPAT_ID,                 //wIndex
        0x01,                               //bCount - 0x01 "Function Section(s)" implemented in this descriptor
        {0,0,0,0,0,0,0},                    //Reserved[7]
        //----------Function Section 1----------
        0x00,                               //bFirstInterfaceNumber: the WinUSB interface in this firmware is interface #0
        0x01,                               //Reserved - fill this reserved byte with 0x01 according to documentation
        {'W','I','N','U','S','B',0x00,0x00},//compatID - "WINUSB" (with two null terminators to fill all 8 bytes)
        {0,0,0,0,0,0,0,0},                  //subCompatID - eight bytes of 0
        {0,0,0,0,0,0}                       //Reserved
    };    
    //Extended Properties OS Feature Descriptor
    const MS_EXT_PROPERTY_FEATURE_DESC ExtPropertyFeatureDescriptor =
    {
        //----------Header Section--------------
        sizeof(ExtPropertyFeatureDescriptor),   //dwLength
        0x0100,                                 //bcdVersion = 1.00
        EXTENDED_PROPERTIES,                    //wIndex
        0x0001,                                 //wCount - 0x0001 "Property Sections" implemented in this descriptor
        //----------Property Section 1----------
        132,                                    //dwSize - 132 bytes in this Property Section
        0x00000001,                             //dwPropertyDataType (Unicode string)
        40,                                     //wPropertyNameLength - 40 bytes in the bPropertyName field
        {'D','e','v','i','c','e','I','n','t','e','r','f','a','c','e','G','U','I','D', 0x0000},  //bPropertyName - "DeviceInterfaceGUID"
        78,                                     //dwPropertyDataLength - 78 bytes in the bPropertyData field (GUID value in UNICODE formatted string, with braces and dashes)
        {'{','5','8','d','0','7','2','1','0','-','2','7','c','1','-','1','1','d','d','-','b','d','0','b','-','0','8','0','0','2','0','0','c','9','a','6','6','}',0x0000}  //bPropertyData - this is the actual GUID value.  Make sure this matches the PC application code trying to connect to the device.
    };    
#endif

#endif