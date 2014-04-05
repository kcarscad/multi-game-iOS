
#import "KCMenuScene.h"
#import "KCMenuButton.h"
#import "KCFlappyGameScene.h"
#import "KCFallScene.h"
#import "KC2048Scene.h"

@interface KCMenuScene()

@property(nonatomic)NSArray *buttons;

-(bool)buttonPressed:(CGRect)rect atLocation:(CGPoint)location;
-(void)switchToFlappyScene;
-(void)switchToFallScene;
-(void)switchToTwentyScene;

@end

@implementation KCMenuScene

-(id)initWithSize:(CGSize)size {
	
    if (self = [super initWithSize:size]){
        
        self.backgroundColor = [SKColor colorWithRed:(161/255.0) green:(202/255.0) blue:(241/255.0) alpha:1.0];
        
        CGFloat width = self.frame.size.width;
        KCMenuButton *flappyButton = [[KCMenuButton alloc]initWithYPosition:100 andFrameWidth:width andText:@"Flappy"];
        KCMenuButton *fallButton   = [[KCMenuButton alloc]initWithYPosition:200 andFrameWidth:width andText:@"Fall"];
        KCMenuButton *twentyButton = [[KCMenuButton alloc]initWithYPosition:300 andFrameWidth:width andText:@"Twenty"];
        
		// make array of all buttons
		self.buttons = @[flappyButton,fallButton,twentyButton];
		
		// add nodes to scene
		for (KCMenuButton *button in self.buttons){
			[self addChild:button];
			[self addChild:button.label];
		}
        
    }
    
    return self;
	
}

// check if button (CGRect) is pressed at certain CGPoint
-(bool)buttonPressed:(CGRect)rect atLocation:(CGPoint)location{
	if (rect.origin.x <= location.x && location.x <= rect.origin.x + rect.size.width &&
		rect.origin.y <= location.y && location.y <= rect.origin.y + rect.size.height){
		return true;
	} return false;
}


// when the screen is touched
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
	UITouch *touch = [touches anyObject];
	
	// grab location of touch
	CGPoint location = [touch locationInNode:self];
	
	// if button is pressed
	for (KCMenuButton *button in self.buttons)
		if ([self buttonPressed:button.rect atLocation:location])
			button.pressed = true;
	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	
	UITouch *touch = [touches anyObject];
	
	// grab location of touch
	CGPoint location = [touch locationInNode:self];
	
	// if touch is moved
	for (KCMenuButton *button in self.buttons){
		if ([self buttonPressed:button.rect atLocation:location]) button.pressed = true;
		else button.pressed  =false;
	}
    
}

// when touch is let go
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	
	UITouch *touch = [touches anyObject];
    
	// grab location of touch
	CGPoint location = [touch locationInNode:self];
	
	// if touch is released on button
	for (KCMenuButton *button in self.buttons){
		if ([self buttonPressed:button.rect atLocation:location]){
			if ([[button identify] isEqualToString:@"Flappy"])
				[self switchToFlappyScene];
			if ([[button identify] isEqualToString:@"Fall"])
				[self switchToFallScene];
            if ([[button identify] isEqualToString:@"Twenty"])
                [self switchToTwentyScene];
			button.pressed = false;
		}
		 
	}
	
}

-(void)switchToFlappyScene{
	
	SKTransition *reveal = [SKTransition fadeWithDuration:1.2];
    KCFlappyGameScene *gameScene = [[KCFlappyGameScene alloc] initWithSize:self.size];
    [self.scene.view presentScene:gameScene transition:reveal];
	
}

-(void)switchToFallScene{
	
	SKTransition *reveal = [SKTransition fadeWithDuration:1.2];
    KCFallScene *gameScene = [[KCFallScene alloc] initWithSize:self.size];
    [self.scene.view presentScene:gameScene transition:reveal];
    
}

-(void)switchToTwentyScene{
    
    SKTransition *reveal = [SKTransition fadeWithDuration:1.2];
    KC2048Scene *gameScene = [[KC2048Scene alloc] initWithSize:self.size];
    [self.scene.view presentScene:gameScene transition:reveal];
    
}

// called before each frame
-(void)update:(CFTimeInterval)currentTime {
	
	for (KCMenuButton *button in self.buttons){
		if (button.isPressed){
			[button setFillColor:[SKColor colorWithRed:(225/255.0) green:(225/255.0) blue:(225/255.0) alpha:1]];
			[button.label setFontColor:[SKColor colorWithRed:(205/255.0) green:(92/255.0) blue:(02/255.0) alpha:1]];
		} else {
			[button setFillColor:[SKColor whiteColor]];
			[button.label setFontColor:[SKColor blackColor]];
		}
	}
	
}

@end
