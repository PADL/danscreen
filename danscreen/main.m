//
//  main.m
//  danscreen
//
//  Created by Luke Howard on 01.10.17.
//  Copyright © 2017 PADL Software Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "CoreDock.h"

CGDirectDisplayID gDisplays[3];
uint32_t gNumDisplays = 0;

static CGError
SwapDockOrientation(void)
{
    CoreDockPinning pinning;
    CoreDockOrientation oldOrientation, newOrientation;
    
    CoreDockGetOrientationAndPinning(&oldOrientation, &pinning);
    
    switch (oldOrientation) {
        case kCoreDockOrientationLeft:
            newOrientation = kCoreDockOrientationRight;
            break;
        case kCoreDockOrientationRight:
            newOrientation = kCoreDockOrientationLeft;
            break;
        default:
            newOrientation = kCoreDockOrientationIgnore;
            break;
    }
    
    if (newOrientation != kCoreDockOrientationIgnore) {
        CoreDockSetOrientationAndPinning(newOrientation, kCoreDockPinningIgnore);
        printf("Changed dock orientation from %s to %s\n",
               oldOrientation == kCoreDockOrientationRight ? "right" : "left",
               newOrientation == kCoreDockOrientationRight ? "right" : "left");
    }
    
    return kCGErrorSuccess;
}

static CGError
EnumerateDisplays(void)
{
    CGError err;
    
    err = CGGetActiveDisplayList(sizeof(gDisplays) / sizeof(gDisplays[0]),
                                 gDisplays, &gNumDisplays);
    if (err != kCGErrorSuccess) {
        fprintf(stderr, "Failed to enumerate displays: %d\n", err);
        return err;
    }
    
    if (gNumDisplays != 2) {
        fprintf(stderr, "Maximum of two displays supported\n");
        return kCGErrorInvalidOperation;
    }
    
    return kCGErrorSuccess;
}

static CGDirectDisplayID
GetSecondaryDisplayID(void)
{
    CGDirectDisplayID primaryDisplay = CGMainDisplayID();
    size_t i;
    
    for (i = 0; i < gNumDisplays; i++) {
        if (gDisplays[i] != primaryDisplay)
            return gDisplays[i];
    }
    
    return 0;
}

static CGError
SwapPrimaryDisplays(void)
{
    CGError err;
    CGDisplayConfigRef config = NULL;
    CGDirectDisplayID primaryDisplay = CGMainDisplayID();
    CGDirectDisplayID secondaryDisplay = GetSecondaryDisplayID();
    
    printf("Primary display ID: %x\n", primaryDisplay);
    printf("Secondary display ID: %x\n", secondaryDisplay);
    
    err = CGBeginDisplayConfiguration(&config);
    if (err != kCGErrorSuccess) {
        fprintf(stderr, "Failed to begin display configuration: %d\n", err);
        return err;
    }
    
    CGRect secondaryBounds = CGDisplayBounds(secondaryDisplay);

    err = CGConfigureDisplayOrigin(config, secondaryDisplay, 0, 0);
    if (err != kCGErrorSuccess) {
        fprintf(stderr, "Failed to set primary display origin: %d\n", err);
        CGCancelDisplayConfiguration(config);
        return err;
    }
    
    err = CGConfigureDisplayOrigin(config, primaryDisplay,
                                   -1 * CGRectGetMinX(secondaryBounds),
                                   -1 * CGRectGetMinY(secondaryBounds));
    if (err != kCGErrorSuccess) {
        fprintf(stderr, "Failed to set secondary display origin: %d\n", err);
        CGCancelDisplayConfiguration(config);
        return err;
    }

    err = CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
    if (err != kCGErrorSuccess) {
        fprintf(stderr, "Failed to complete display configuration: %d\n", err);
        return err;
    }
    
    printf("Display %x is now primary display.\n", secondaryDisplay);

    return kCGErrorSuccess;
}

int main(int argc, const char * argv[]) {
    CGError err;
    
    @autoreleasepool {
        err = EnumerateDisplays();
        if (err == kCGErrorSuccess) {
          err = SwapPrimaryDisplays();
        }
        if (err == kCGErrorSuccess) {
            err = SwapDockOrientation();
        }
    }
    return err;
}
