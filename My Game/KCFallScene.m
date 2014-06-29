
/* GRID
 *
 * starts from bottom left
 * centered at the center of objects
 *
 */

#import "KCFallScene.h"
#import "KCMenuScene.h"

int BETWEENOBSTACLES = 300;
static const uint32_t playerCategory = 0x1 << 0;
static const uint32_t otherCategory = 0x1 << 1;

@interface KCFallScene()

@property(nonatomic)SKSpriteNode *player, *popup;
@property(nonatomic)NSMutableArray *fallingObjects;
@property(nonatomic)SKLabelNode *scoreNode, *finalScoreNode, *messageNode;
@property(nonatomic)bool running;

-(void)createNode:(NSString *)node;
-(void)setPlayerPosition:(UIEvent *)event;

@end

@implementation KCFallScene{
	float lastObstacleAdditionTimeInterval,lastUpdateTimeInterval;
	int score,c;
	bool popupActionDone, notTappedYet, changing;
}

#pragma mark init

-(id)initWithSize:(CGSize)size{
	
	if (self = [super initWithSize:size]){
		
		[self setBackgroundColor:[SKColor colorWithRed:(161/255.0) green:(202/255.0) blue:(241/255.0) alpha:1.0]];
		self.physicsWorld.gravity = CGVectorMake(0.0, -2.5);
		self.physicsWorld.contactDelegate = self;
		self.fallingObjects = [NSMutableArray array];
		score = c = 0;
		notTappedYet = changing = true;
		popupActionDone = false;
		
		lastObstacleAdditionTimeInterval = 0.0;
		lastUpdateTimeInterval = 0.0;
		self.running = false;
		
		[self createNode:@"player"];
		[self createNode:@"score"];
		[self createNode:@"tapToContinue"];
		
	}
	
	return self;

}

-(void)createNode:(NSString *)node{
	
	if ([node isEqualToString:@"player"]){
		
		self.player = [[SKSpriteNode alloc]init];
		[self.player setSize:CGSizeMake(50, 25)];
		[self.player setPosition:CGPointMake(self.frame.size.width/2.0,self.frame.size.height/4.0)];
		[self.player setColor:[SKColor blackColor]];
		[self.player setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:self.player.size]];
		self.player.physicsBody.dynamic = false;
		[self addChild:self.player];
		self.player.physicsBody.categoryBitMask = playerCategory;
		self.player.physicsBody.collisionBitMask = otherCategory;
		self.player.physicsBody.contactTestBitMask = otherCategory;
		self.player.physicsBody.usesPreciseCollisionDetection = true;

	} else if ([node isEqualToString:@"score"]){
		
		score = 0;
		self.scoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
		self.scoreNode.text = [NSString stringWithFormat:@"%d",score];
		self.scoreNode.fontSize = 28;
		self.scoreNode.fontColor = [SKColor whiteColor];
		self.scoreNode.position = CGPointMake(self.frame.size.width/2.0, self.frame.size.height - 60);
		[self addChild:self.scoreNode];
		
	} else if ([node isEqualToString:@"fallingObject"]){
        
        float x,y;
        
        SKSpriteNode *object = [SKSpriteNode spriteNodeWithImageNamed:@"circle"];
        [object setScale:0.5];
        
        y = self.frame.size.height + object.frame.size.height/2.0;
        
        if (![self.fallingObjects count]){
            x = floorf(((double)arc4random() / 0x100000000) * (self.frame.size.width - object.frame.size.width)) + object.frame.size.width/2.0;
        } else {
            
            float deviation = arc4random_uniform(50) + object.frame.size.width/2.0;
            
            if ([self.fallingObjects count]==1)
                x = [self.fallingObjects[0] position].x + (arc4random_uniform(2)==0 ? -1 : 1) * deviation;
            else {
                if ([self.fallingObjects[[self.fallingObjects count]-1] position].x < [self.fallingObjects[[self.fallingObjects count]-2] position].x)
                    x = [self.fallingObjects[[self.fallingObjects count]-1] position].x + (arc4random_uniform(7)==0 ? 1 : -1) * deviation;
                else
                    x = [self.fallingObjects[[self.fallingObjects count]-1] position].x + (arc4random_uniform(7)==0 ? -1 : 1) * deviation;
            }
            
            if (x - object.frame.size.width/2.0 <= 0){
                x = object.frame.size.width + [self.fallingObjects[[self.fallingObjects count]-1] position].x;
            } else if (x + object.frame.size.width/2.0 >= self.frame.size.width){
                x = [self.fallingObjects[[self.fallingObjects count]-1] position].x-object.frame.size.width;
            }
            
        }
        
        [object setPosition:CGPointMake(x, y)];
        [object setPhysicsBody:[SKPhysicsBody bodyWithCircleOfRadius:object.frame.size.width/2.0]];
        object.physicsBody.dynamic = true;
        [self addChild:object];
        [self.fallingObjects addObject:object];
		
	} else if ([node isEqualToString:@"fadeOut"]){
		
		SKSpriteNode *fadeOut = [[SKSpriteNode alloc]init];
		[fadeOut setSize:CGSizeMake(self.frame.size.width,self.frame.size.height)];
		[fadeOut setPosition:CGPointMake(self.frame.size.width/2.0,self.frame.size.height/2.0)];
		[fadeOut setColor:[SKColor blackColor]];
		[fadeOut setAlpha:0.0];
		[self addChild:fadeOut];
		
		[fadeOut runAction:[SKAction fadeAlphaTo:0.7 duration:0.5]];

	} else if ([node isEqualToString:@"popup"]){
		
		[self createNode:@"fadeOut"];
		self.running = false;
		
		for (SKSpriteNode *object in self.fallingObjects) [object.physicsBody setVelocity:CGVectorMake(0.0, 0.0)];
		self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
		
		// fade out score #
		[self.scoreNode runAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:0.5],
													   [SKAction removeFromParent]]]];
        
        self.finalScoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
		self.finalScoreNode.text = [NSString stringWithFormat:@"Score: %d",score];
		self.finalScoreNode.fontSize = 50;
		self.finalScoreNode.fontColor = [SKColor whiteColor];
		self.finalScoreNode.position = CGPointMake(self.frame.size.width/2.0, 3*self.frame.size.height/5.0);
        [self.finalScoreNode setScale:8.0];
        self.finalScoreNode.alpha = 0.0;
        
        [self addChild:self.messageNode];
        [self addChild:self.finalScoreNode];
        
        // set the action for each node
        SKAction *action = [SKAction sequence:@[[SKAction sequence:@[[SKAction waitForDuration:0.5],
                                                                     [SKAction group:@[[SKAction fadeInWithDuration:0.5],
                                                                                       [SKAction scaleTo:1.0 duration:0.8]]]]],
                                                [SKAction runBlock:^(void){popupActionDone=true;}]]];

        [self.finalScoreNode runAction:action];
		
	} else if ([node isEqualToString:@"tapToContinue"]){
		
		// set properties/behaviour for 'tap to continue' before game
		self.messageNode = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
		self.messageNode.text = [NSString stringWithFormat:@"Tap anywhere to start!"];
		self.messageNode.fontSize = 23;
		self.messageNode.fontColor = [SKColor whiteColor];
		self.messageNode.alpha = 0.0;
		self.messageNode.position = CGPointMake(self.frame.size.width/2.0, 3*self.frame.size.height/4.0 - self.messageNode.frame.size.height/2.0);
		[self addChild:self.messageNode];
		
		[self.messageNode runAction:[SKAction fadeAlphaTo:1.0 duration:0.5]];
		
	}
	
}

#pragma mark touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	
	if (self.running)
        [self setPlayerPosition:event];
	
	else if (notTappedYet) {
		
		self.running = true;
		notTappedYet = false;
		[self.messageNode runAction:[SKAction sequence:@[[SKAction fadeAlphaTo:0.0 duration:0.5],
														 [SKAction removeFromParent]]]];
		
		[self setPlayerPosition:event];
		
	} else if (popupActionDone)
        [self switchToMenuScene];
	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	
	if (self.running) [self setPlayerPosition:event];
	
}

-(void)setPlayerPosition:(UIEvent *)event{
	
	CGFloat xLocation = [[[event allTouches]anyObject] locationInView:self.view].x;
	[self.player setPosition:CGPointMake(xLocation,self.player.position.y)];
	
}

#pragma mark update

-(void)update:(NSTimeInterval)currentTime{
	
	if (self.running && [self.fallingObjects count]!=0){
		SKSpriteNode *object = self.fallingObjects[0];
		if (object.position.y + object.frame.size.height < self.player.position.y) [self createNode:@"popup"];
	}
		
	CFTimeInterval timeSinceLast = currentTime - lastUpdateTimeInterval;
	lastUpdateTimeInterval = currentTime;
	if (timeSinceLast > BETWEENOBSTACLES/1000.0) {
		timeSinceLast = 1.0 / 60.0;
		lastUpdateTimeInterval = currentTime;
	} [self updateWithTimeSinceLastUpdate:timeSinceLast];
	
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
	
	if (self.running){
		lastObstacleAdditionTimeInterval += timeSinceLast;
		if (lastObstacleAdditionTimeInterval > BETWEENOBSTACLES/1000.0) {
            if (changing){
                c+=1;
                // every 15 balls, decrease interval, increase gravity
                if (c%15==0){
                    BETWEENOBSTACLES -= 15;
                    [self.physicsWorld setGravity:CGVectorMake(0.0, self.physicsWorld.gravity.dy-0.5)];
                    c=0;
                }
                if (BETWEENOBSTACLES <= 100.0) changing=false;
            }
            
			lastObstacleAdditionTimeInterval = 0;
			[self createNode:@"fallingObject"];
		}
	}
	
}

#pragma mark -

- (void)didBeginContact:(SKPhysicsContact *)contact{
	
	SKPhysicsBody *firstBody = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB;
	if (firstBody.categoryBitMask != 0) {
		[self.fallingObjects[0] removeFromParent];
		[self.fallingObjects removeObject:self.fallingObjects[0]];
		self.scoreNode.text = [NSString stringWithFormat:@"%d",++score];
	}
	
}

// switch back to the menu
-(void)switchToMenuScene{
	
	SKTransition *reveal = [SKTransition fadeWithDuration:1.2];
	
	KCMenuScene *gameScene = [[KCMenuScene alloc]initWithSize:self.size];
	[self.scene.view presentScene:gameScene transition:reveal];
	
}

@end
