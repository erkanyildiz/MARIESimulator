//
//  EYMARIESimulatorViewController.h
//  MARIESimulator
//
//  Created by Erkan YILDIZ on 03/05/14.
//  Copyright (c) 2014 Erkan YILDIZ. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - MARIE Instructions

#define kLOAD        @"LOAD"
#define kSTORE       @"STORE"
#define kLOADI       @"LOADI"
#define kSTOREI       @"STOREI"

#define kADD         @"ADD"
#define kSUBT        @"SUBT"
#define kADDI        @"ADDI"
#define kCLEAR       @"CLEAR"

#define kINPUT       @"INPUT"
#define kOUTPUT      @"OUTPUT"

#define kJUMP        @"JUMP"
#define kJUMPI       @"JUMPI"
#define kJNS         @"JNS"
#define kSKIPCOND    @"SKIPCOND"

#define kHALT        @"HALT"

#define kORG         @"ORG"
#define kEND         @"END"
#define kDEC         @"DEC"
#define kHEX         @"HEX"



@interface EYMARIESimViewController : UIViewController
{
    NSInteger AC;
    NSInteger PC;
    NSInteger IR;
    NSInteger MAR;
    NSInteger MBR;
    NSInteger INREG;
    NSInteger OUTREG;
}


@property (strong, nonatomic) NSMutableArray* RAM;
@property (strong, nonatomic) NSMutableDictionary* labels;
@property (strong, nonatomic) NSArray* opcodes;

#pragma mark - Outlets
@property (strong, nonatomic) IBOutlet UITextView *txt_source;
@property (strong, nonatomic) IBOutlet UITextView *txt_memory;
@property (strong, nonatomic) IBOutlet UITextView *txt_labels;

- (IBAction)onClick_load:(id)sender;

@end
