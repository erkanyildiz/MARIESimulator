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
    
    
    vw_PCI = [[UIView alloc] initWithFrame:(CGRect){296,32,40,INDICATOR_HEIGHT}];
    vw_PCI.alpha = 0.5;
    vw_PCI.backgroundColor = UIColor.redColor;
    [self.view addSubview:vw_PCI];

    vw_MARI = [[UIView alloc] initWithFrame:(CGRect){296,32,40,INDICATOR_HEIGHT}];
    vw_MARI.alpha = 0.5;
    vw_MARI.backgroundColor = UIColor.yellowColor;
    [self.view addSubview:vw_MARI];
    vw_MARI.hidden = YES;
    

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
    
    
    IndicatorOffset = PC;
    [self updateIndicators];

    vw_PCI.hidden=YES;
    
    
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
            
            self.txt_memory.text = [self.txt_memory.text stringByAppendingFormat:@"%@  %@%@\n", address,prepadding,instructionHex ];
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


-(void)updateIndicators
{
    vw_PCI.center = (CGPoint){vw_PCI.center.x,32+INDICATOR_HEIGHT/2.0+(PC-IndicatorOffset)*INDICATOR_HEIGHT};

    vw_MARI.center = (CGPoint){vw_MARI.center.x,32+INDICATOR_HEIGHT/2.0+(MAR-IndicatorOffset)*INDICATOR_HEIGHT};
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
            self.txt_labels.text = [self.txt_labels.text stringByAppendingFormat:@"%@  %@\n", hex(index), label];

            if ([parts[0] isEqualToString:kDEC] || [parts[0] isEqualToString:kHEX])
            {
                NSLog(@"Label with DEC or HEX detected on line %lu", (unsigned long)idx);
                
                NSInteger immediateValue = ([parts[0] isEqualToString:kHEX])?dec(parts[1]):([parts[1] integerValue] + MAXWORD) % MAXWORD;
                self.RAM[index]  = @(immediateValue);
            }
        }
    }];
    
    
    
#pragma mark INSTRUCTION check
    
    [lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSLog(@"Line %lu: %@", (unsigned long)idx, obj);

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
    
    IndicatorOffset = PC;
    
    [self updateRegisters];
    [self updateIndicators];
    vw_PCI.hidden=NO;
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
        NSLog(@"SUB AC %li",(long)AC);
    }
    else if([opcodeStr isEqualToString:kINPUT])
    {
        INREG = dec(self.txt_INREG.text);
        AC = INREG;
    }
    else if([opcodeStr isEqualToString:kOUTPUT])
    {
        OUTREG = AC;
        self.lbl_OUTREG.text = hex4digit(OUTREG);
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
            NSLog(@"SKIPCOND negative %li",(long)operand);
            PC++;
        }
        else if (operand == 4*256 && AC == 0)
        {
            NSLog(@"SKIPCOND zero %li",(long)operand);
            PC++;
        }
        else if (operand == 8*256 && AC < MAXWORD/2 && AC != 0)
        {
            NSLog(@"SKIPCOND positive %li",(long)operand);
            PC++;
        }
    }

    
    
    [self updateRegisters];
    [self updateRAM];
    [self updateIndicators];
    
    if(shouldContinueExecuting && ![opcodeStr isEqualToString:kHALT])
       [self performSelector:@selector(runLoop) withObject:nil afterDelay:executionDelay];
}

#pragma mark - User Interaction

- (IBAction)onClick_load:(id)sender
{
    if([self.txt_source.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"SOURCE field is empty!\n Use EXAMPLE codes or write your own code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }

    
    [self parse:self.txt_source.text];
}

- (IBAction)onClick_example0:(id)sender
{
    switch ([sender tag])
    {
        case 100:
            self.txt_source.text =
            @"LOAD X\n"
            "ADD Y\n"
            "SUBT Z\n"
            "STORE SONUC\n"
            "OUTPUT\n"
            "HALT\n"
            "X, DEC 10\n"
            "Y, DEC 20\n"
            "Z, DEC 5\n"
            "SONUC DEC 0\n";
            
            [self clear];

            break;

        case 101:
            self.txt_source.text =
            @"START, CLEAR\n"
            "STORE C\n"
            "STORE TEMP\n"
            "LOOP, LOAD TEMP\n"
            "ADDI I\n"
            "STORE TEMP\n"
            "LOAD C\n"
            "ADD INC\n"
            "STORE C\n"
            "SUBT M\n"
            "SKIPCOND 400\n"
            "JUMP LOOP\n"
            "LOAD TEMP\n"
            "STOREI I\n"
            "LOAD I\n"
            "ADD INC\n"
            "STORE I\n"
            "SUBT LAST\n"
            "SKIPCOND 400\n"
            "JUMP START\n"
            "HALT\n"
            "I, HEX 210\n"
            "LAST, HEX 22F\n"
            "C, DEC 0\n"
            "TEMP, DEC 0\n"
            "INC, DEC 1\n"
            "M, DEC 8\n"
            "END\n";
            
            [self clear];

            break;

        case 102:
            self.txt_source.text =
            @"LOAD FIB1\n"
            "STOREI I\n"
            "JNS SBR\n"
            "LOAD FIB2\n"
            "STOREI I\n"
            "JNS SBR\n"
            "LOOP, CLEAR\n"
            "ADD FIB1\n"
            "ADD FIB2\n"
            "STOREI I\n"
            "LOAD FIB2\n"
            "STORE FIB1\n"
            "LOADI I\n"
            "STORE FIB2\n"
            "JNS SBR\n"
            "JUMP LOOP\n"
            "SBR, HEX 0\n"
            "LOAD I\n"
            "ADD INC\n"
            "STORE I\n"
            "LOAD LIMIT\n"
            "SUBT INC\n"
            "STORE LIMIT\n"
            "SKIPCOND 400\n"
            "JUMPI SBR\n"
            "HALT\n"
            "I, HEX 4FF\n"
            "LIMIT, DEC 50\n"
            "FIB1, DEC 0\n"
            "FIB2, DEC 1\n"
            "INC, DEC 1\n"
            "END\n";

            [self clear];

            break;

        case 103:
            self.txt_source.text =
            @"ZERO, CLEAR\n"
            "LOADI I\n"
            "SKIPCOND 400\n"
            "JUMP POSITIVE\n"
            "LOADI CZ\n"
            "ADD INC\n"
            "STOREI CZ\n"
            "JUMP LOOP\n"
            "POSITIVE, SKIPCOND 800\n"
            "JUMP NEGATIVE\n"
            "LOADI CP\n"
            "ADD INC\n"
            "STOREI CP\n"
            "JUMP LOOP\n"
            "NEGATIVE, LOADI CN\n"
            "ADD INC\n"
            "STOREI CN\n"
            "LOOP, LOAD I\n"
            "ADD INC\n"
            "STORE I\n"
            "SUBT LAST\n"
            "SKIPCOND 800\n"
            "JUMP ZERO\n"
            "HALT\n"
            "I, HEX 350\n"
            "LAST, HEX 36F\n"
            "CP, HEX 500\n"
            "CN, HEX 501\n"
            "CZ, HEX 502\n"
            "INC, DEC 1\n";

            [self clear];

            break;


        case 200:
            for (NSInteger i=dec(@"210"); i<=dec(@"22F"); i++)
                self.RAM[i]=@(arc4random()%100);
            
            [self updateRAM];
            
            break;

        case 300:
            for (NSInteger i=dec(@"350"); i<=dec(@"36F"); i++)
                self.RAM[i]=@(arc4random()%MAXWORD);
            
            self.RAM[dec(@"500")] = @0;
            self.RAM[dec(@"501")] = @0;
            self.RAM[dec(@"502")] = @0;
            
            [self updateRAM];
            
            break;
            
        case 999:
            
            self.txt_source.text = @"";
            [self clear];

            break;

            
        default:
            break;
    }
    
}


- (IBAction)onClick_run:(id)sender
{
    if([self.txt_memory.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to LOAD first!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    shouldContinueExecuting = YES;
    executionDelay=0.2;
    [self runLoop];
}


- (IBAction)onClick_step:(id)sender
{
    if([self.txt_memory.text isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to LOAD first!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(runLoop) object:nil];
    shouldContinueExecuting = NO;
    executionDelay=0.0;
    [self runLoop];
}


#pragma mark - Helpers

NSString* hex(NSInteger d)
{
    return [NSString stringWithFormat:@"%03lx",(long)d].uppercaseString;
}


NSString* hex4digit(NSInteger d)
{
    return [NSString stringWithFormat:@"%04lx",(long)d].uppercaseString;
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



#pragma mark - Tests & ToDos

//EXECUTE
//DONE: check JNS
//DONE: check SKIPCOND
//DONE: handle ORG 0 -1 +1
//DONE: comma parse for JUMP and DEC/HEX
//DONE: prevent run before loading and setting random memory
//DONE: NSNull intValue 0 category

//UI
//TODO: scrollable line numbers
//TODO: tableview instead of textview for RAM
//DONE: PC indicator
//TODO: prevent repetetive run
//TODO: slider for speed

//PARSE
//TODO: DEC HEX before HALT
//TODO: same labels used again
//TODO: whitespace parsing
//TODO: more than one ORG
//TODO: direct RAM edit
//TODO: labels with tab indent

@end



#pragma mark - NSNull+IntegerValue

@interface NSNull (IntegerValue)
-(NSInteger)integerValue;
@end

@implementation NSNull (IntegerValue)
-(NSInteger)integerValue
{
    return 0;
}
@end
