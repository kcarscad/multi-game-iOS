
#import <SpriteKit/SpriteKit.h>

@interface KCMenuButton : SKShapeNode

@property(nonatomic)CGRect rect;
@property(nonatomic,retain)SKLabelNode *label;
@property(nonatomic,getter=isPressed)bool pressed;

-(NSString *)identify;

-(id)initWithYPosition:(CGFloat)yPosition andFrameWidth:(CGFloat)frameWidth andText:(NSString *)text;

@end
