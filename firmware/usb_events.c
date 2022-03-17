#include "usb.h"
#include "usb_device.h"
#include "usb_device_generic.h"

#include "bulkEP0.h"

bool USER_USB_CALLBACK_EVENT_HANDLER(USB_EVENT event, void *pdata, uint16_t size){
    switch((int)event){
        case EVENT_TRANSFER:
            break;

        case EVENT_SOF:
            break;

        case EVENT_SUSPEND:
            break;

        case EVENT_RESUME:
            break;

        case EVENT_CONFIGURED:
            bulkEP0_init();
            break;

        case EVENT_SET_DESCRIPTOR:
            break;

        case EVENT_EP0_REQUEST:
            USBCheckVendorRequest();
            break;

        case EVENT_BUS_ERROR:
            break;

        case EVENT_TRANSFER_TERMINATED:
            break;

        default:
            break;
    }
    return true;
}