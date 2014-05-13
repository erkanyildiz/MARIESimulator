//
//  EYMARIESimulatorViewController.m
//  MARIESimulator
//
//  Created by Erkan YILDIZ on 03/05/14.
//  Copyright (c) 2014 Erkan YILDIZ. All rights reserved.
//

#import "EYMARIESimViewController.h"

@interface EYMARIESimViewController ()

@end

@implementation EYMARIESimViewController

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


-(BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.opcodes = [NSArray arrayWithObjects:
                    kJNS,
                    kLOAD,
                    kSTORE,
                    kADD,
                    kSUBT,
                    kINPUT,
                    kOUTPUT,
                    kHALT,
                    kSKIPCOND,
                    kJUMP,
                    kCLEAR,
                    kADDI,
                    kJUMPI,
                    kSTOREI,
                    kLOADI,
                    nil];
    
    [self clear];
}



#pragma mark - Simulator

-(void)clear
{
    AC = 0;
    PC = 0;
    IR = 0;
    MAR = 0;
    MBR = 0;
    INREG = 0;
    OUTREG = 0;
    
    [self updateRegisters];
    
    self.RAM = nil;
    self.RAM = [NSMutableArray arrayWithCapacity:MAXWORD];
    for (int i=0; i<MAXWORD; i++)
    {
        [self.RAM addObject:[NSNull null]];
    }
    
    self.labels = nil;
    self.labels = [NSMutableDictionary dictionary];
    
    //    self.txt_source.text = @"";
    self.txt_labels.text = @"";
    self.txt_memory.text = @"";
    
    isHalted = NO;
}


-(void)updateRAM
{
    self.txt_memory.text = @"";
    
    [self.RAM enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         if(![obj isEqual:[NSNull null]])
         {
             NSString* address = hex(idx);
             NSString* instructionHex = hex([self.RAM[idx] integerValue]);
             NSString* prepadding = (instructionHex.length < 4)?@"0":@"";
             
             self.txt_memory.text = [self.txt_memory.text stringByAppendingFormat:@"%@ %@%@\n", address,prepadding,instructionHex ];
         }
     }];
}


-(void)updateRegisters
{
    self.lbl_AC.text = hex4digit(AC);
    self.lbl_MAR.text = hex4digit(MAR);
    self.lbl_MBR.text = hex4digit(MBR);
    self.lbl_IR.text = hex4digit(IR);
    self.lbl_PC.text = hex4digit(PC);
    self.lbl_OUTREG.text = hex4digit(OUTREG);
    self.txt_INREG.text = hex4digit(INREG);
}


-(void)parse:(NSString*)source
{
    [self clear];
    
    NSArray* lines = [source.uppercaseString componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    
    
    
#pragma mark ORG check on the first line
    
    NSInteger offset = 0;
    NSArray *parts = [lines[0] componentsSeparatedByString:@" "];
    if ([parts[0] isEqualToString:kORG])
    {
        NSLog(@"%@ detected",kORG);
        offset = dec(parts[1])-1;
    }
    
    
    
#pragma mark LABEL check
    
    [lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSArray* commaSeparated = [obj componentsSeparatedByString:@","];
         
         if (commaSeparated.count == 2)
        {
             NSArray* parts = [[commaSeparated[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] componentsSeparatedByString:@" "];

             NSString *label = commaSeparated[0];
             NSInteger index = offset + idx;
             
             self.labels[label] = @(index);
             self.txt_labels.text = [self.txt_labels.text stringByAppendingFormat:@"%@ %@\n", label, hex(index)];

            if ([parts[0] isEqualToString:kDEC] || [parts[0] isEqualToString:kHEX])
            {
                NSLog(@"Label with DEC or HEX detected on line %i", idx);
                
                NSInteger immediateValue = ([parts[0] isEqualToString:kHEX])?dec(parts[1]):([parts[1] integerValue] + MAXWORD) % MAXWORD;
                self.RAM[index]  = @(immediateValue);
            }
        }
     }];
    
    
    
#pragma mark INSTRUCTION check
    
    [lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         NSLog(@"Line %i: %@", idx, obj);
         
         NSString* forSpaceSeparate = obj;
         NSArray* commaSeparated = [obj componentsSeparatedByString:@","];
         if(commaSeparated.count == 2)
             forSpaceSeparate = [commaSeparated[1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
         
         NSArray* parts = [forSpaceSeparate componentsSeparatedByString:@" "];

         NSInteger opcode = [self.opcodes indexOfObject:parts[0]];
         
         if (opcode != NSNotFound)
         {
             NSInteger index = offset+idx;
             NSInteger operand = (parts.count == 1)?0:[self.labels[parts[1]] integerValue];
             if([parts[0] isEqualToString:kSKIPCOND]) operand = dec(parts[1]);
             NSInteger instruction = opcode*4096+operand;
             
             self.RAM[index] = @(instruction);
         }
     }];
    
    [self updateRAM];

    PC = offset;
    
    if([parts[0] isEqualToString:kORG])
        PC++;
    
    [self updateRegisters];
}


-(void)runLoop
{
    NSLog(@"%s",__FUNCTION__);
    
    if(isHalted)
        return;

    //NOTE: fetch
    MAR = PC;
    IR = [self.RAM[MAR] integerValue];
    PC++;

    //NOTE: decode
    NSInteger opcode = IR/4096;
    NSInteger operand = IR%4096;
    NSString* opcodeStr = self.opcodes[opcode];
    
    NSLog(@"%@ %@", hex(opcode), opcodeStr);
    
    //NOTE: execute
    if([opcodeStr isEqualToString:kHALT])
    {
        NSLog(@"HALT");
        isHalted = YES;
    }
    else if([opcodeStr isEqualToString:kLOAD])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        AC = MBR;
    }
    else if([opcodeStr isEqualToString:kLOADI])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        MAR = MBR;
        MBR = [self.RAM[MAR] integerValue];
        AC = MBR;
    }
    else if([opcodeStr isEqualToString:kSTORE])
    {
        MAR = operand;
        MBR = AC;
        self.RAM[MAR] = @(MBR);
    }
    else if([opcodeStr isEqualToString:kSTOREI])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        MAR = MBR;
        MBR = AC;
        self.RAM[MAR] = @(MBR);
    }
    else if([opcodeStr isEqualToString:kADD])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        AC = (AC + MBR) % MAXWORD;
    }
    else if([opcodeStr isEqualToString:kADDI])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        MAR = MBR;
        MBR = [self.RAM[MAR] integerValue];
        AC = (AC + MBR) % MAXWORD;
    }
    else if([opcodeStr isEqualToString:kSUBT])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        AC = ((AC - MBR) + MAXWORD) % MAXWORD;
        NSLog(@"SUB AC %i",AC);
    }
    else if([opcodeStr isEqualToString:kINPUT])
    {
        AC = INREG;
    }
    else if([opcodeStr isEqualToString:kOUTPUT])
    {
        OUTREG = AC;
    }
    else if([opcodeStr isEqualToString:kCLEAR])
    {
        AC = 0;
    }
    else if([opcodeStr isEqualToString:kJUMP])
    {
        PC = operand;
    }
    else if([opcodeStr isEqualToString:kJUMPI])
    {
        MAR = operand;
        MBR = [self.RAM[MAR] integerValue];
        PC = MBR;
    }
    else if([opcodeStr isEqualToString:kJNS])
    {
        MBR = PC;
        MAR = operand;
        self.RAM[MAR] = @(MBR);
        MBR = operand;
        AC = 1;
        AC = (AC + MBR) % MAXWORD;
        PC = AC;
    }
    else if ([opcodeStr isEqualToString:kSKIPCOND])
    {
        if(operand == 0 && AC >= MAXWORD/2)
        {
            NSLog(@"SKIPCOND negative %i",operand);
            PC++;
        }
        else if (operand == 4*256 && AC == 0)
        {
            NSLog(@"SKIPCOND zero %i",operand);
            PC++;
        }
        else if (operand == 8*256 && AC < MAXWORD/2 && AC != 0)
        {
            NSLog(@"SKIPCOND positive %i",operand);
            PC++;
        }
    }

    
    
    [self updateRegisters];
    [self updateRAM];
    
    if(shouldContinueExecuting && ![opcodeStr isEqualToString:kHALT])
       [self performSelector:@selector(runLoop) withObject:nil afterDelay:executionDelay];
}

#pragma mark - User Interaction

- (IBAction)onClick_load:(id)sender
{
    [self parse:self.txt_source.text];
}

- (IBAction)onClick_example0:(id)sender
{
    self.txt_source.text =
    @"LOAD X\n"
    "ADD Y\n"
    "SUBT Z\n"
    "STORE SONUC\n"
    "OUTPUT\n"
    "HALT\n"
    "X DEC 10\n"
    "Y DEC 20\n"
    "Z DEC 5\n"
    "SONUC DEC 0\n";
}


- (IBAction)onClick_run:(id)sender
{
    shouldContinueExecuting = YES;
    executionDelay=0.2;
    [self runLoop];
}


- (IBAction)onClick_step:(id)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(runLoop) object:nil];
    shouldContinueExecuting = NO;
    executionDelay=0.0;
    [self runLoop];
}


#pragma mark - Helpers

NSString* hex(NSInteger d)
{
    return [NSString stringWithFormat:@"%03x",d].uppercaseString;
}


NSString* hex4digit(NSInteger d)
{
    return [NSString stringWithFormat:@"%04x",d].uppercaseString;
}


NSInteger dec(NSString* h)
{
    int sign = 1;
    if([h characterAtIndex:0] == '-')
    {
        sign = -1;
        h = [h substringFromIndex:1];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:h];
    unsigned int dec;
    [scanner scanHexInt:&dec];
    
    return ((sign*dec) + MAXWORD) % MAXWORD;
}

#pragma mark - Tests

//EXECUTE
//DONE: check JNS
//DONE: check SKIPCOND
//DONE: handle ORG 0 -1 +1
//DONE: comma parse for JUMP and DEC/HEX

//UI
//TODO: Add line numbers (scrollable)
//TODO: tableview instead of textview for RAM
//TODO: PC indicator
//TODO: run clear for re-run
//TODO: run disable before loading
//TODO: slider for speed

//PARSE
//TODO: DEC HEX before HALT
//TODO: same labels used again
//TODO: whitespace parsing
//TODO: more than one ORG

@end
