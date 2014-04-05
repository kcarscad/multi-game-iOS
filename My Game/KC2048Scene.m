//
//  KC2048Scene.m
//  My Game
//
//  Created by Keith Carscadden on 2014-03-28.
//  Copyright (c) 2014 Keith Carscadden. All rights reserved.
//

#import "KC2048Scene.h"

const CGFloat DURATION = 0.2;

@interface KC2048Scene()

-(void)createBase;
-(void)createBoxesArray:(SKSpriteNode *)box;
-(void)createNewBox;
-(int)determineDirection;
-(bool)updateBoxes;
-(bool)transitionBoxFrom:(NSArray *)initial to:(NSArray *)final;
-(NSArray *)pt:(int)a :(int)b;
-(NSArray *)createBox:(NSArray *)point withColor:(SKColor *)color start:(bool)start;
-(int)combineNumbers:(bool)inXDimension withX:(int)x andY:(int)y andBox1:(NSArray *)box1 andBox2:(NSArray *)box2 andD:(int)d;
@end

@implementation KC2048Scene{
    CGPoint startPos,endPos;
    NSArray *boxes;
    NSMutableArray *nodesOnScreen;
    bool occupiedBoxes[4][4];
    SKColor *BASEBOXCOLOR;
}

#pragma mark init

-(id)initWithSize:(CGSize)size{
	
	if (self = [super initWithSize:size]){
		
		[self setBackgroundColor:[SKColor colorWithRed:(161/255.0) green:(202/255.0) blue:(241/255.0) alpha:1.0]];
        
        BASEBOXCOLOR = [SKColor colorWithRed:255/255.0 green:198/255.0 blue:41/255.0 alpha:1.0];
        
        // (x,y) E [0,3]
        // @[x, y, box, label]
        nodesOnScreen = [NSMutableArray array];
        
        for (int a=0;a<4;a++)
            for (int b=0;b<4;b++)
                occupiedBoxes[a][b]=0;
                
        [self createBase];
        
	}
	
	return self;
    
}

#pragma mark -
#pragma mark update boxes

-(int)determineDirection{
    
    // up down left right
    
    int direction[4] = {0,0,0,0};
    
    if (startPos.x < endPos.x) direction[3]=(endPos.x-startPos.x);
    else direction[2]=(startPos.x-endPos.x);
    if (startPos.y < endPos.y) direction[1]=(endPos.y-startPos.y);
    else direction[0]=(startPos.y-endPos.y);
    
    if (abs(startPos.x - endPos.x) > abs(startPos.y - endPos.y)) direction[1] = direction[0] = 0;
    else direction[3] = direction[2] = 0;
    
    int i;
    for (i=0;i<4;i++)
        if (direction[i] != 0 && direction[i] >= 15)
            return i;
    
    return -1;
    
}

-(NSArray *)pt:(int)a :(int)b{
    return @[[NSNumber numberWithInt:a],[NSNumber numberWithInt:b]];
}

// move boxes after swipe
-(bool)updateBoxes{
    
    NSMutableArray *newPoints = [NSMutableArray array];
    NSMutableArray *oldPoints = [NSMutableArray array];
    
    int c=0;
    
    // changes due to swipes
    switch ([self determineDirection]){
            
        // not enough of a swipe
        case -1:
            break;
            
        // up
        case 0:
            
            for (int y=3;y>=0;y--)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (b < 3 && !occupiedBoxes[a][b+1]){
                            occupiedBoxes[a][b+1]=1;
                            occupiedBoxes[a][b++]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // down
        case 1:
            
            for (int y=0;y<4;y++)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (b > 0 && !occupiedBoxes[a][b-1]) {
                            occupiedBoxes[a][b-1]=1;
                            occupiedBoxes[a][b--]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // left
        case 2:
            
            for (int x=0;x<4;x++)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (a > 0 && !occupiedBoxes[a-1][b]) {
                            occupiedBoxes[a-1][b]=1;
                            occupiedBoxes[a--][b]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                    }
            
            break;
            
        // right
        case 3:
            
            for (int x=3;x>=0;x--)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y]){
                        int a=x, b=y;
                        oldPoints[c] = [self pt:a:b];
                        while (a < 3 && !occupiedBoxes[a+1][b]) {
                            occupiedBoxes[a+1][b]=1;
                            occupiedBoxes[a++][b]=0;
                        }
                        newPoints[c++] = [self pt:a:b];
                        
                    }
        
            break;
            
        default:
            exit(0);
    }
    
    bool moved = 0;
    
    // transition all boxes
    for (int i=0;i<c;i++)
        if ([newPoints[i][0] intValue] != [oldPoints[i][0] intValue] || [newPoints[i][1] intValue] != [oldPoints[i][1] intValue])
            if ([self transitionBoxFrom:oldPoints[i] to:newPoints[i]])
                moved=1;
    
    switch ([self determineDirection]){
            
        case -1:
            break;
            
        // up
        case 0:
            
            // combine boxes if necessary
            for (int y=2;y>=0;y--)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y] && occupiedBoxes[x][y+1]){
                        
                        NSArray *box1, *box2;
                        int c=0,d=0;
                        
                        // get the 2 box arrays
                        for (NSArray *array in nodesOnScreen){
                            if (x == [array[0] intValue] && y == [array[1] intValue]){
                                box1 = array;
                                d=c;
                            } else if (x == [array[0] intValue] && y+1 == [array[1] intValue])
                                box2 = array;
                            c+=1;
                        }
                        
                        // if they have the same number, combine em
                        if ([[box1[3] text] isEqualToString:[box2[3] text]])
                            moved = [self combineNumbers:0 withX:x andY:y andBox1:box1 andBox2:box2 andD:d];
                        
                    }
            
            // go back and transition any other boxes that were left behind
            for (int x=0;x<4;x++)
                for (int y=2;y>=0;y--)
                    if (occupiedBoxes[x][y] && !occupiedBoxes[x][y+1]){
                        
                        SKAction *action = [SKAction moveBy:CGVectorMake(0, [boxes[0][1][1] intValue]-[boxes[0][0][1] intValue]) duration:DURATION];
                        NSMutableArray *tempNodesOnScreen = [NSMutableArray arrayWithArray:nodesOnScreen];
                        
                        int c=0;
                        for (NSArray *array in nodesOnScreen){
                            
                            if ([array[0] intValue] == x && [array[1] intValue] == y){
                                
                                [array[2] runAction:action];
                                tempNodesOnScreen[c] = @[[NSNumber numberWithInt:x],[NSNumber numberWithInt:y+1],array[2],array[3]];
                                
                                [nodesOnScreen[c][3] runAction:action];
                                nodesOnScreen = [NSMutableArray arrayWithArray:tempNodesOnScreen];
                                
                                occupiedBoxes[x][y]=0;
                                occupiedBoxes[x][y+1]=1;
                                
                                moved = 1;
                                
                            }
                            c+=1;
                        }
                        
                    }
            
            break;
            
        // down
        case 1:
            
            // combine boxes if necessary
            for (int y=1;y<4;y++)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y] && occupiedBoxes[x][y-1]){
                        
                        NSArray *box1, *box2;
                        int c=0,d=0;
                        
                        // get the 2 box arrays
                        for (NSArray *array in nodesOnScreen){
                            if (x == [array[0] intValue] && y == [array[1] intValue]){
                                box1 = array;
                                d=c;
                            } else if (x == [array[0] intValue] && y-1 == [array[1] intValue])
                                box2 = array;
                            c+=1;
                        }
                        
                        // if they have the same number, combine em
                        if ([[box1[3] text] isEqualToString:[box2[3] text]])
                            moved = [self combineNumbers:0 withX:x andY:y andBox1:box1 andBox2:box2 andD:d];

                    }
            
            // go back and transition any other boxes that were left behind
            for (int y=1;y<4;y++)
                for (int x=0;x<4;x++)
                    if (occupiedBoxes[x][y] && !occupiedBoxes[x][y-1]){
                        
                        SKAction *action = [SKAction moveBy:CGVectorMake(0, [boxes[0][0][1] intValue]-[boxes[0][1][1] intValue]) duration:DURATION];
                        NSMutableArray *tempNodesOnScreen = [NSMutableArray arrayWithArray:nodesOnScreen];
                        
                        int c=0;
                        for (NSArray *array in nodesOnScreen){
                            
                            if ([array[0] intValue] == x && [array[1] intValue] == y){
                                
                                [array[2] runAction:action];
                                tempNodesOnScreen[c] = @[[NSNumber numberWithInt:x],[NSNumber numberWithInt:y-1],array[2],array[3]];
                                
                                [nodesOnScreen[c][3] runAction:action];
                                nodesOnScreen = [NSMutableArray arrayWithArray:tempNodesOnScreen];
                                
                                occupiedBoxes[x][y]=0;
                                occupiedBoxes[x][y-1]=1;
                                
                                moved = 1;
                                
                            }
                            c+=1;
                        }
                        
                    }
            
            break;
            
        // left
        case 2:
            
            // combine boxes if necessary
            for (int x=1;x<4;x++)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y] && occupiedBoxes[x-1][y]){
                        
                        NSArray *box1, *box2;
                        int c=0,d=0;
                        
                        // get the 2 box arrays
                        for (NSArray *array in nodesOnScreen){
                            if (x == [array[0] intValue] && y == [array[1] intValue]){
                                box1 = array;
                                d=c;
                            } else if (x-1 == [array[0] intValue] && y == [array[1] intValue])
                                box2 = array;
                            c+=1;
                        }
                        
                        // if they have the same number, combine em
                        if ([[box1[3] text] isEqualToString:[box2[3] text]])
                            moved = [self combineNumbers:1 withX:x andY:y andBox1:box1 andBox2:box2 andD:d];
                        
                    }
            
            // go back and transition any other boxes that were left behind
            for (int x=1;x<4;x++)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y] && !occupiedBoxes[x-1][y]){
                        
                        SKAction *action = [SKAction moveBy:CGVectorMake([boxes[0][0][0] intValue]-[boxes[1][0][0] intValue], 0) duration:DURATION];
                        NSMutableArray *tempNodesOnScreen = [NSMutableArray arrayWithArray:nodesOnScreen];
                        
                        int c=0;
                        for (NSArray *array in nodesOnScreen){
                            
                            if ([array[0] intValue] == x && [array[1] intValue] == y){
                                
                                [array[2] runAction:action];
                                tempNodesOnScreen[c] = @[[NSNumber numberWithInt:x-1],[NSNumber numberWithInt:y],array[2],array[3]];
                                
                                [nodesOnScreen[c][3] runAction:action];
                                nodesOnScreen = [NSMutableArray arrayWithArray:tempNodesOnScreen];
                                
                                occupiedBoxes[x][y]=0;
                                occupiedBoxes[x-1][y]=1;
                                
                                moved = 1;
                                
                            }
                            c+=1;
                        }
                        
                    }

            
            break;
            
        // right
        case 3:
            
            // combine boxes if necessary
            for (int x=2;x>=0;x--)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y] && occupiedBoxes[x+1][y]){
                        
                        NSArray *box1, *box2;
                        int c=0,d=0;
                        
                        // get the 2 box arrays
                        for (NSArray *array in nodesOnScreen){
                            if (x == [array[0] intValue] && y == [array[1] intValue]){
                                box1 = array;
                                d=c;
                            } else if (x+1 == [array[0] intValue] && y == [array[1] intValue])
                                box2 = array;
                            c+=1;
                        }
                        
                        // if they have the same number, combine em
                        if ([[box1[3] text] isEqualToString:[box2[3] text]])
                            moved = [self combineNumbers:1 withX:x andY:y andBox1:box1 andBox2:box2 andD:d];
                        
                    }
            
            // go back and transition any other boxes that were left behind
            for (int x=2;x>=0;x--)
                for (int y=0;y<4;y++)
                    if (occupiedBoxes[x][y] && !occupiedBoxes[x+1][y]){
                        
                        SKAction *action = [SKAction moveBy:CGVectorMake([boxes[1][0][0] intValue]-[boxes[0][0][0] intValue], 0) duration:DURATION];
                        NSMutableArray *tempNodesOnScreen = [NSMutableArray arrayWithArray:nodesOnScreen];
                        
                        int c=0;
                        for (NSArray *array in nodesOnScreen){
                            
                            if ([array[0] intValue] == x && [array[1] intValue] == y){
                                
                                [array[2] runAction:action];
                                tempNodesOnScreen[c] = @[[NSNumber numberWithInt:x+1],[NSNumber numberWithInt:y],array[2],array[3]];
                                
                                [nodesOnScreen[c][3] runAction:action];
                                nodesOnScreen = [NSMutableArray arrayWithArray:tempNodesOnScreen];
                                
                                occupiedBoxes[x][y]=0;
                                occupiedBoxes[x+1][y]=1;
                                
                                moved = 1;
                                
                            }
                            c+=1;
                        }
                        
                    }

            
            break;
            
        default:
            exit(0);
            
    }
    
    return moved;
    
}

-(int)combineNumbers:(bool)inXDimension withX:(int)x andY:(int)y andBox1:(NSArray *)box1 andBox2:(NSArray *)box2 andD:(int)d{
    
    CGFloat dx,dy;
    
    if (inXDimension){
        int n1 = [box1[0] intValue];
        int n2 = [box2[0] intValue];
        dx = [boxes[n2][0][0] floatValue] - [boxes[n1][0][0] floatValue];
        dy = 0;
    } else {
        int n1 = [box1[1] intValue];
        int n2 = [box2[1] intValue];
        dx = 0;
        dy = [boxes[0][n2][1] floatValue] - [boxes[0][n1][1] floatValue];
    }
    
    SKLabelNode *mainLabel = box2[3];
    SKShapeNode *oldBox = box1[2];
    SKLabelNode *oldLabel = box1[3];
    
    SKAction *oldAction1 = [SKAction fadeOutWithDuration:DURATION];
    SKAction *oldAction2 = [SKAction moveByX:dx y:dy duration:DURATION];
    SKAction *oldAction3 = [SKAction runBlock:^{
        [oldBox removeFromParent];
        [oldLabel removeFromParent];
    }];
    
    SKAction *newAction1 = [SKAction fadeOutWithDuration:DURATION];
    SKAction *newAction2 = [SKAction runBlock:^{
        mainLabel.text = [NSString stringWithFormat:@"%d",[mainLabel.text intValue]*2];
        [mainLabel setAlpha:0.0];
    }];
    SKAction *newAction3 = [SKAction fadeAlphaTo:1.0 duration:DURATION];
    
    [oldLabel runAction:[SKAction group:@[oldAction1,oldAction2]]];
    [oldBox runAction:[SKAction sequence:@[[SKAction group:@[oldAction1,oldAction2]],oldAction3]]];
    
    [mainLabel runAction:[SKAction sequence:@[newAction1,newAction2,newAction3]]];
    
    [nodesOnScreen removeObjectAtIndex:d];
    
    occupiedBoxes[x][y]=0;
    
    return 1;
    
}

#pragma mark -
#pragma mark touches

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    startPos = [[[event allTouches]anyObject] locationInView:self.view];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    endPos = [[[event allTouches]anyObject] locationInView:self.view];
    if ([self updateBoxes])
        [self createNewBox];
    
}

#pragma mark -
#pragma mark create,createNew,transition

// random box creation after each swipe
-(void)createNewBox{
    
    // wait for a certain duration, then
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.3],
                                         [SKAction runBlock:^{
        
        int x,y;
        
        // get coords that aren't taken
        do {
            x = arc4random_uniform(4);
            y = arc4random_uniform(4);
        } while (occupiedBoxes[x][y]==1);
        
        // adds data to nodesOnScreen, && draws the box
        NSArray *array = [self createBox:boxes[x][y] withColor:[SKColor blackColor] start:0];
        [nodesOnScreen addObject:@[[NSNumber numberWithInt:x],[NSNumber numberWithInt:y],array[0],array[1]]];
        occupiedBoxes[x][y] = 1;
        
    }]]]];
    
}

// draw a box given a point
-(NSArray *)createBox:(NSArray *)point withColor:(SKColor *)color start:(bool)start {
    
    CGRect rect = CGRectMake([point[0] floatValue], [point[1] floatValue], [point[2] floatValue], [point[3] floatValue]);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRoundedRect(path, NULL, rect, 5, 5);
    
    SKShapeNode *box = [SKShapeNode node];
    box.path = path;
    box.fillColor = color;
    box.strokeColor = color;
    
    if (start){
    
        [self addChild:box];
        return @[box];
        
    // fade in
    } else {
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Avenir"];
        
        [label setFontColor:[SKColor whiteColor]];
        [label setFontSize:40.0];
        [label setPosition:CGPointMake([point[0] floatValue] + [point[2] floatValue]/2.0, [point[1] floatValue] + [point[3] floatValue]/4.0)];
        if (arc4random_uniform(101) >= 40) [label setText:@"2"];
        else [label setText:@"4"];
        
        box.alpha = 0.0;
        label.alpha = 0.0;
        SKAction *action = [SKAction fadeInWithDuration:0.4];
        
        [box runAction:action];
        [label runAction:action];
        
        [self addChild:box];
        [self addChild:label];
        
        return @[box,label];

    }
    
}

// transitions a box from pt to pt, updating variables
-(bool)transitionBoxFrom:(NSArray *)initial to:(NSArray *)final{
    
    int x1 = [initial[0] intValue], y1 = [initial[1] intValue];
    int x2 = [final[0] intValue], y2 = [final[1] intValue];
    
    NSMutableArray *tempNodesOnScreen = [NSMutableArray arrayWithArray:nodesOnScreen];
    int c=0;
    
    // cycle through boxes that are drawn already
    for (NSArray *box in nodesOnScreen){
        
        // if the coords of 'box' match our x1, x2
        if ([box[0] intValue] == x1 && [box[1] intValue] == y1){
            
            CGFloat dx = [boxes[x2][y2][0] floatValue] - [boxes[x1][y1][0] floatValue];
            CGFloat dy = [boxes[x2][y2][1] floatValue] - [boxes[x1][y1][1] floatValue];
            
            SKAction *action = [SKAction moveBy:CGVectorMake(dx, dy) duration:DURATION];
            
            // move, then change temp array for new data
            [box[2] runAction:action];
            tempNodesOnScreen[c] = @[[NSNumber numberWithInt:x2],[NSNumber numberWithInt:y2],box[2],box[3]];
            [nodesOnScreen[c][3] runAction:action];
            nodesOnScreen = [NSMutableArray arrayWithArray:tempNodesOnScreen];
            
            return 1;
            
        }
        c+=1;
    }
    
    // should never reach
    exit(0);
    
}

#pragma mark -
#pragma mark use once

// create the x,y,w,h boxes array
-(void)createBoxesArray:(SKSpriteNode *)box{
    
    NSMutableArray *tempBoxes = [NSMutableArray array];
    
    for (int x=box.frame.size.width/8.0;x<box.frame.size.width;x+=box.frame.size.width/4.0){
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int y=box.frame.size.height/8.0;y<box.frame.size.height;y+=box.frame.size.height/4.0){
            [tempArray addObject:@[[NSNumber numberWithFloat:box.position.x-box.frame.size.width/2.0 + (x - box.frame.size.width/5.0/2.0)],[NSNumber numberWithFloat:box.position.y-box.frame.size.height/2.0 + (y - box.frame.size.height/5.0/2.0)],[NSNumber numberWithFloat:box.frame.size.width/5.0],[NSNumber numberWithFloat:box.frame.size.height/5.0]]];
        }
        [tempBoxes addObject:tempArray];
    }
    
    boxes = [NSMutableArray arrayWithArray:tempBoxes];
    
}
// start up
-(void)createBase{
    
    SKSpriteNode *box = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:(255/255.0) green:(143/255.0) blue:(0/255.0) alpha:1] size:CGSizeMake(300, 300)];
    [box setPosition:CGPointMake(self.frame.size.width/2.0,7*self.frame.size.height/18.0)];
    [self addChild:box];
    
    // create the array of boxes
    [self createBoxesArray:box];
    
    for (NSMutableArray *array in boxes)
        for (NSMutableArray *point in array)
            [self createBox:point withColor:BASEBOXCOLOR start:1];
    
    // pick random box, start with that
    [self createNewBox];
    
}

@end
