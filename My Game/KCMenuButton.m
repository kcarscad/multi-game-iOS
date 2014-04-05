
#import "KCMenuButton.h"

@implementation KCMenuButton

-(id)initWithYPosition:(CGFloat)yPosition andFrameWidth:(CGFloat)frameWidth andText:(NSString *)text{

    if (self=[super init]){
        
        CGFloat width = 200;
        
        self.rect = CGRectMake(frameWidth/2.0-width/2.0, yPosition, width, 75);
        self.pressed = false;
        CGMutablePathRef path = CGPathCreateMutable();
		CGPathAddRoundedRect(path, NULL, self.rect, 10.0, 10.0);
        self.path=path;
        
        self.lineWidth = 1.0;
        self.fillColor = [SKColor whiteColor];
        self.strokeColor = [SKColor colorWithRed:(255/255.0) green:(143/255.0) blue:(0/255.0) alpha:1];
        
        self.label=[[SKLabelNode alloc]init];
        self.label.fontName = @"Avenir";
        self.label.text=text;
        self.label.fontSize = 30;
        self.label.fontColor = [SKColor blackColor];
        self.label.position = CGPointMake(CGRectGetMidX(self.rect),CGRectGetMidY(self.rect)-frameWidth/30.0);
        
    }
    
    return self;
}

-(NSString *)identify { return self.label.text; }

@end
