
/* GRID
 *
 * starts from bottom left
 * centered at the center of objects
 *
 */

#import "KCFlappyGameScene.h"
#import "KCMenuScene.h"
#import "KCViewController.h"

static const CGFloat BETWEENOBSTACLES = 2.0;
static const CGFloat SPEEDACROSSSCREEN = 120.0;
static const uint32_t circleCategory = 0x1 << 0;
static const uint32_t otherCategory = 0x1 << 1;

@interface KCFlappyGameScene()

@property(nonatomic)SKSpriteNode *circle, *popup, *base1, *base2, *BASE;
@property(nonatomic)SKLabelNode *scoreNode, *finalScoreNode, *messageNode;
@property(nonatomic)NSMutableArray *obstacles;
@property(nonatomic,assign)BOOL running;
@property(nonatomic)SKAction *moveBaseSpritesForever;

-(void)switchToMenuScene;
-(void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast;
-(void)createNode:(NSString *)node;

@end

#pragma mark -

@implementation KCFlappyGameScene{
	float lastUpdateTimeInterval,lastObstacleAdditionTimeInterval,lastBase1AdditionTimeInterval,lastBase2AdditionTimeInterval;
	bool popupActionDone,scoreAllowed,notTappedYet;
	int score;
}

#pragma mark init

-(id)initWithSize:(CGSize)size{
	 
	if (self = [super initWithSize:size]){
		
		// initial values
		[self setBackgroundColor:[SKColor colorWithRed:(161/255.0) green:(202/255.0) blue:(241/255.0) alpha:1.0]];
		self.physicsWorld.gravity = CGVectorMake(0.0, 0);
		self.physicsWorld.contactDelegate = self;
		self.obstacles = [NSMutableArray array];
		lastObstacleAdditionTimeInterval = lastUpdateTimeInterval = 0;
		lastBase1AdditionTimeInterval = self.frame.size.width/SPEEDACROSSSCREEN;
		lastBase2AdditionTimeInterval = 2.0*self.frame.size.width/SPEEDACROSSSCREEN;
		popupActionDone = scoreAllowed = self.running = false;
		notTappedYet = true;
		
		[self createNode:@"base"];
		[self createNode:@"circle"];
		[self createNode:@"score"];
		[self createNode:@"tapToContinue"];
		
		self.moveBaseSpritesForever = [SKAction sequence:@[[SKAction moveByX:2*self.frame.size.width y:0.0 duration:0.0],
														   [SKAction moveByX:-2.0*self.frame.size.width y:0.0 duration:2.0*self.frame.size.width/SPEEDACROSSSCREEN]]];
		
		[self.base1 runAction:[SKAction moveByX:-self.frame.size.width y:0.0 duration:self.frame.size.width/SPEEDACROSSSCREEN]];
				
	}
	
	return self;
}

#pragma mark node creation

-(void)createNode:(NSString *)node{
	
	if ([node isEqualToString:@"score"]){
		
		score = 0;
		self.scoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
		self.scoreNode.text = [NSString stringWithFormat:@"%d",score];
		self.scoreNode.fontSize = 35;
		self.scoreNode.fontColor = [SKColor whiteColor];
		self.scoreNode.position = CGPointMake(self.frame.size.width/2.0, self.frame.size.height - 80);
		[self addChild:self.scoreNode];
		
	} else if ([node isEqualToString:@"base"]){
		
		self.base1 = [SKSpriteNode spriteNodeWithImageNamed:@"base"];
		[self.base1 setScale:1.0];
		self.base1.position =CGPointMake(self.base1.size.width/2.0, self.base1.size.height/2.0);
		[self.base1 setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:self.base1.size]];
		self.base1.physicsBody.affectedByGravity = false;
		self.base1.physicsBody.dynamic = false;
		
		self.base2 = [SKSpriteNode spriteNodeWithImageNamed:@"base"];
		[self.base2 setScale:1.0];
		self.base2.position =CGPointMake(-self.base2.size.width/2.0, self.base2.size.height/2.0);
		[self.base2 setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:self.base2.size]];
		self.base2.physicsBody.affectedByGravity = false;
		self.base2.physicsBody.dynamic = false;
		
		self.BASE = [[SKSpriteNode alloc]init];
		[self.BASE setSize:CGSizeMake(self.frame.size.width,self.base1.size.height)];
		[self.BASE setPosition:CGPointMake(self.BASE.size.width/2.0,self.BASE.size.height/2.0)];
		[self.BASE setScale:1.0];
		[self.BASE setColor:[SKColor colorWithRed:(10.0/255.0) green:(204.0/255.0) blue:(15.0/255.0) alpha:1.0]];
		[self.BASE setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:self.BASE.size]];
		self.BASE.physicsBody.affectedByGravity = false;
		self.BASE.physicsBody.dynamic = false;
		
		[self addChild:self.BASE];
		[self addChild:self.base1];
		[self addChild:self.base2];
		
	} else if ([node isEqualToString:@"circle"]){
		
		self.circle = [SKSpriteNode spriteNodeWithImageNamed:@"circle"];
		[self.circle setScale:0.7];
		self.circle.position = CGPointMake(self.frame.size.width/3.0, 2.0*self.frame.size.height/3.0 - self.circle.frame.size.height/2.0);
		self.circle.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.circle.frame.size.height/2.0];
		self.circle.physicsBody.dynamic = true;
		[self addChild:self.circle];
		self.circle.physicsBody.categoryBitMask = circleCategory;
		self.circle.physicsBody.collisionBitMask = otherCategory;
		self.circle.physicsBody.contactTestBitMask = otherCategory;
		self.circle.physicsBody.usesPreciseCollisionDetection = false;

	} else if ([node isEqualToString:@"obstacle"]){
		
		if (self.running){
			
			float opening = self.frame.size.height/5.0;
			float yPadding = opening/2.0;
			float width = 75.0;
			
			float randomHeight = floorf(((double)arc4random() / 0x100000000) * (self.frame.size.height - self.base1.frame.size.height - 2*yPadding - opening)) + yPadding;
						
			SKSpriteNode *obstacle1 = [[SKSpriteNode alloc]init];
			SKSpriteNode *obstacle2 = [[SKSpriteNode alloc]init];
			[obstacle1 setSize:CGSizeMake(width, randomHeight)];
			[obstacle2 setSize:CGSizeMake(width, (self.frame.size.height - randomHeight - opening))];
			[obstacle1 setPosition:CGPointMake(self.frame.size.width + obstacle1.frame.size.width/2.0, self.base1.frame.size.height + obstacle1.frame.size.height - obstacle1.frame.size.height/2.0)];
			[obstacle2 setPosition:CGPointMake(self.frame.size.width + obstacle2.frame.size.width/2.0, self.base1.frame.size.height + obstacle1.frame.size.height + opening + obstacle2.frame.size.height/2.0)];
			[obstacle1 setColor:[SKColor blackColor]];
			[obstacle2 setColor:[SKColor blackColor]];
			[obstacle1 setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:obstacle1.size]];
			[obstacle2 setPhysicsBody:[SKPhysicsBody bodyWithRectangleOfSize:obstacle2.size]];
			obstacle1.physicsBody.affectedByGravity = false;
			obstacle2.physicsBody.affectedByGravity = false;
			obstacle1.physicsBody.dynamic = false;
			obstacle2.physicsBody.dynamic = false;
			
			[self addChild:obstacle1];
			[self addChild:obstacle2];
			[self.scoreNode removeFromParent];
			[self addChild:self.scoreNode];
			
			scoreAllowed = true;
						
			[self.obstacles addObjectsFromArray:@[obstacle1,obstacle2]];
			
			// move both obstacles across screen
			// afterwards, remove obstacles from array
			SKAction *sequence1 = [SKAction sequence:@[[SKAction moveByX:-(self.frame.size.width + obstacle1.frame.size.width) y:0.0 duration:(self.frame.size.width + obstacle1.frame.size.width)/SPEEDACROSSSCREEN],[SKAction removeFromParent]]];
			SKAction *sequence2 = [SKAction sequence:@[[SKAction moveByX:-(self.frame.size.width + obstacle2.frame.size.width) y:0.0 duration:(self.frame.size.width + obstacle2.frame.size.width)/SPEEDACROSSSCREEN],[SKAction group:@[[SKAction removeFromParent],[SKAction runBlock:^{[self.obstacles removeObject:obstacle1];[self.obstacles removeObject:obstacle2];}]]]]];
			
			[obstacle1 runAction:sequence1];
			[obstacle2 runAction:sequence2];
			
		}
		
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
				
		// fade out score #
		[self.scoreNode runAction:[SKAction sequence:@[[SKAction fadeOutWithDuration:0.5],
													   [SKAction removeFromParent]]]];
        
        for (SKSpriteNode *obstacle in self.obstacles) [obstacle removeAllActions];
		[self.base1 removeAllActions];
		[self.base2 removeAllActions];
        
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

	} else if ([node isEqualToString:@"finalScore"]){
		
		// set properties for final score text
		self.finalScoreNode = [SKLabelNode labelNodeWithFontNamed:@"Futura-Medium"];
		self.finalScoreNode.text = [NSString stringWithFormat:@"Score: %d",score];
		self.finalScoreNode.fontSize = 35;
		self.finalScoreNode.fontColor = [SKColor blackColor];
		self.finalScoreNode.position = CGPointMake(self.frame.size.width/2.0, self.popup.position.y - self.finalScoreNode.frame.size.height/2.0);
		[self addChild:self.finalScoreNode];
		
	} else if ([node isEqualToString:@"gameOver"]){
		
		// set properties for 'game over' text
		self.messageNode.text = [NSString stringWithFormat:@"Game Over"];
		self.messageNode.fontSize = 40;
		self.messageNode.fontColor = [SKColor whiteColor];
		self.messageNode.alpha = 0.0;
		self.messageNode.position = CGPointMake(self.frame.size.width/2.0, self.frame.size.height - self.popup.frame.size.height);
		[self addChild:self.messageNode];
		
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
    
	if (popupActionDone) [self switchToMenuScene];

	// on 'tap', start game, get rid of message, start base movement
	if (notTappedYet) {
		self.running = true;
		notTappedYet = false;
		self.physicsWorld.gravity = CGVectorMake(0,-9.0);
		[self.messageNode runAction:[SKAction sequence:@[[SKAction fadeAlphaTo:0.0 duration:0.5],
														 [SKAction removeFromParent]]]];
						
	}
	
	if (self.running) [self.circle.physicsBody setVelocity:CGVectorMake(self.circle.physicsBody.velocity.dx, 400.0)];
			
}

#pragma mark update

-(void)update:(NSTimeInterval)currentTime {

    // keep the base moving
	if ((!self.running && notTappedYet) || self.running){
		if (![self.base1 hasActions])[self.base1 runAction:self.moveBaseSpritesForever];
		if (![self.base2 hasActions])[self.base2 runAction:self.moveBaseSpritesForever];
    }
    
    // score, top collision
	if (self.running){
				
		// add score
        // take the last obstacle object in the list, watch for its score
		if ([self.obstacles count] && scoreAllowed){
			SKSpriteNode *obstacle = [self.obstacles lastObject];
            if (obstacle.position.x-obstacle.frame.size.width/3.0 <= self.circle.position.x){
				self.scoreNode.text = [NSString stringWithFormat:@"%d",++score];
				scoreAllowed = false;
			}
		}
		
		// circle hits the top
		if (self.circle.position.y > self.frame.size.height - self.circle.size.height/2.0){
			[self.circle setPosition:CGPointMake(self.circle.position.x, self.size.height - self.circle.size.height/2.0)];
			[self.circle.physicsBody setVelocity:CGVectorMake(self.circle.physicsBody.velocity.dx, 0.0)];
		}
		
	}
	
	// Apple's update method
	CFTimeInterval timeSinceLast = currentTime - lastUpdateTimeInterval;
	lastUpdateTimeInterval = currentTime;
	if (timeSinceLast > BETWEENOBSTACLES) {
		timeSinceLast = 1.0 / 60.0;
		lastUpdateTimeInterval = currentTime;
	} [self updateWithTimeSinceLastUpdate:timeSinceLast];
			
}

// Apple's update method
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
	
	if (self.running){
		lastObstacleAdditionTimeInterval += timeSinceLast;
		if (lastObstacleAdditionTimeInterval > BETWEENOBSTACLES) {
			lastObstacleAdditionTimeInterval = 0;
			[self createNode:@"obstacle"];
		}
	}
	
}

#pragma mark other events

// when there's contact
- (void)didBeginContact:(SKPhysicsContact *)contact{
		
	if (self.running){
		SKPhysicsBody *firstBody = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB;
		if (firstBody.categoryBitMask != 0) [self createNode:@"popup"];
	}
	
}

// switch back to the menu
-(void)switchToMenuScene{
		
	SKTransition *reveal = [SKTransition fadeWithDuration:1.2];
	
	KCMenuScene *gameScene = [[KCMenuScene alloc]initWithSize:self.size];
	[self.scene.view presentScene:gameScene transition:reveal];
	
}

@end
