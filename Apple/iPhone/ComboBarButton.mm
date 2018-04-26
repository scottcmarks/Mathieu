//
//  ComboBarButton.m
//  Mathieu
//
//  Created by Scott Marks on 04/20/2018.
//

#import "GameModel.h"
#import "ComboBarButton.h"

static NSString * inverse=@"⁻¹";

@interface ComboBarButton()
@property (nonatomic, assign) HistoryElement comboName;
@property (nonatomic, assign) bool isTimerRunning;
@property (nonatomic, assign) bool isPseudoDisabled;
@end
@implementation ComboBarButton
@synthesize target;
@synthesize comboName;
@synthesize isTimerRunning;
@synthesize isPseudoDisabled;

- (void) awakeFromNib {
    [super awakeFromNib];
    self.comboName = (HistoryElement)[self.defaultTitle characterAtIndex:0];
    self.alternateTitle=[NSString stringWithFormat:@"%c%@", self.comboName, inverse];
    isTimerRunning = false;
}

-(void) startTimer {
    @synchronized(self) {
        [self performSelector: @selector( timerExpired )
                   withObject: nil
                   afterDelay: MACROPRESSTIME ];
        isTimerRunning = true;
    }
}

-(bool) stopTimer {
    @synchronized(self) {
        bool timerWasRunning = isTimerRunning;
        isTimerRunning = false;
        [ NSObject cancelPreviousPerformRequestsWithTarget:self
                                                  selector: @selector( timerExpired )
                                                    object: nil ] ;
        return timerWasRunning;
    }
}

- ( void ) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"ComboBarButton: touchesBegan") ;
    [self startTimer];
}

- ( void ) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"ComboBarButton: touchesEnded") ;
    if (![self stopTimer]) return;
    if (self.alternate)
        [target comboInverseInvoked:self.comboName];
    else
        [target comboInvoked:self.comboName];
}

- (void) timerExpired
{
//    NSLog(@"ComboBarButton: timerExpired") ;
    if (![self stopTimer]) return;
    [target comboSet:self.comboName];
}

- (BOOL) disabled {return self.isPseudoDisabled;}

- (void) setDisabled:(BOOL)d {
    self.isPseudoDisabled = d;
    UIColor * c = (d ? [UIColor darkGrayColor] : [UIColor whiteColor]);
    [self setTitleColor:c forState:self.state];
    return;
}

@end
