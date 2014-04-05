
#import "KCViewController.h"
#import "KCMenuScene.h"

@implementation KCViewController

- (void)viewWillLayoutSubviews {
	
    [super viewWillLayoutSubviews];
	
	// hide status bar (ios 7,6)
	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	else
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    // configure the SpriteKit view (same as UIView)
    SKView* skView = (SKView *)self.view;
	 
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // create/configure the scene (same size as skView, which is the same size as the UIView)
    SKScene* scene = [KCMenuScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;

    // present the scene
    [skView presentScene:scene];
	
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)handleApplicationWillResignActive:(NSNotification*)note{
    ((SKView*)self.view).paused = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
