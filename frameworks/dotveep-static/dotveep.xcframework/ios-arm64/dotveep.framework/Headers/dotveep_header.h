//
//  dotveep.h
//  dotveep
//
//  Created by jonathan on 20/05/2023.
//

/*
 
 dotveep_header.h
 
 Renamed from dotveep.h as the header file cannot share the same name as ${PRODUCT_NAME}
 
 If the name is shared, expect errors:
 "umbrella header for module 'dotveep' does not include header 'VPKGPBArray_PackagePrivate.h'"

 */

#import <Foundation/Foundation.h>

//! Project version number for dotveep.
FOUNDATION_EXPORT double dotveepVersionNumber;

//! Project version string for dotveep.
FOUNDATION_EXPORT const unsigned char dotveepVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <dotveep/PublicHeader.h>

#import <dotveep/Veep.pbobjc.h>

