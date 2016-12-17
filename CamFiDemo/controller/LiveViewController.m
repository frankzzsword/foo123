#import "CamFiAPI.h"
#import "CamFiServerInfo.h"
#import "LiveViewController.h"
#import "Utils.h"
#import "CamFiDemo-Swift.h"

#define ISYUVDATAWHENTAKEVIDEO NO
#define ISCANONCAMERA YES

static NSInteger skipCount = -1;
static BOOL soi = NO;

@interface LiveViewController ()

@property (nonatomic, strong) NSMutableURLRequest* photoStreamURLRequest;
@property (nonatomic, strong) NSURLConnection* photoStreamURLConnection;
@property (nonatomic, strong) NSMutableData* photoData;
@property (nonatomic, assign) NSInteger metaDataStartIndex;
@property (nonatomic, strong) UIView *whiteScreen;


@property (weak, nonatomic) IBOutlet UIImageView* previewImageView;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;

@property (assign, nonatomic) NSUInteger secondsLeft;

@end


@implementation LiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start/Stop" style:UIBarButtonItemStylePlain target:self action:@selector(toggleBarButtonItemPressed:)];
    self.whiteScreen = [[UIView alloc] initWithFrame:self.view.frame];
    self.whiteScreen.layer.opacity = 0.0f;
    self.whiteScreen.layer.backgroundColor = [[UIColor whiteColor] CGColor];
    [self.view addSubview:self.whiteScreen];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self toggleBarButtonItemPressed:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self takePictureWithCountdown:3.0 onCompletion:^
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
                [self takePictureWithCountdown:3.0 onCompletion:^
                {
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7 * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        PreviewViewController *vc = (PreviewViewController *)
                        [storyboard instantiateViewControllerWithIdentifier:@"Preview"];
                        
                        [self showViewController:vc sender:nil];
                    });
                    
                }];
            });
        }];
    });
}


-(void)flashScreen {
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    NSArray *animationValues = @[ @0.8f, @0.0f ];
    NSArray *animationTimes = @[ @0.1f, @0.6f ];
    id timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    NSArray *animationTimingFunctions = @[ timingFunction, timingFunction ];
    [opacityAnimation setValues:animationValues];
    [opacityAnimation setKeyTimes:animationTimes];
    [opacityAnimation setTimingFunctions:animationTimingFunctions];
    opacityAnimation.fillMode = kCAFillModeForwards;
    opacityAnimation.removedOnCompletion = YES;
    opacityAnimation.duration = 0.5;
    
    [self.whiteScreen.layer addAnimation:opacityAnimation forKey:@"animation"];
}

- (void)takePictureWithCountdown:(NSTimeInterval)seconds onCompletion:(dispatch_block_t)completion
{
    if (seconds == 0)
    {
        [self flashScreen];
        self.countdownLabel.text = @"";
        NSLog(@"take a picture");

        [self takePicture];

        if (completion != nil)
        {
            completion();
        }
    }
    else
    {
        CATransition *animation = [CATransition animation];
        animation.duration = 0.1;
        animation.type = kCATransitionPush;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [_countdownLabel.layer addAnimation:animation forKey:@"changeTextTransition"];

        
        self.countdownLabel.text = [@(seconds) description];
        
        seconds -= 1;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self takePictureWithCountdown:seconds onCompletion:completion];
        });
    }
}

- (void)takePicture
{
    [CamFiAPI camFiTakePicture:^(NSError *error, id responseObject)
    {
        if (error)
        {
            AFLogDebug(@"error:%@", error);
        }
        else
        {
            AFLogDebug(@"responseObject:%@", responseObject);
            
            //We were able to successfully take the picture
            
            NSData *imageData = [NSData dataWithData:responseObject];
            UIImage *image = [UIImage imageWithData:imageData];
            self.view.backgroundColor = [UIColor colorWithPatternImage:image];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopLiveShow];
}

#pragma mark - Actions

- (void)toggleBarButtonItemPressed:(id)sender
{
    if (_photoStreamURLConnection) {

        [self stopLiveShow];
    }
    else {

        [self startLiveShow];
    }
}

- (void)startLiveShow
{
    [HUDHelper hudWithView:self.view andMessage:nil];
    [CamFiAPI camFiStartLiveShow:^(NSError* error) {
        if (error) {
            [HUDHelper hudWithView:self.view andError:error];
        }
        else {
            
            [HUDHelper hiddAllHUDForView:self.view animated:YES];
            [self setUpPhotoStreamURLRequest];
        }
    }];
}

- (void)stopLiveShow
{
    [HUDHelper hudWithView:self.view andMessage:nil];
    [CamFiAPI camFiStopLiveShow:^(NSError* error) {
        [_photoStreamURLConnection cancel];
        _photoStreamURLConnection = nil;

        if (error) {

            [HUDHelper hudWithView:self.view andError:error];
        }
        else {

            [HUDHelper hiddAllHUDForView:self.view animated:YES];
        }
    }];
}

- (void)setUpPhotoStreamURLRequest
{
    NSURL* url = [NSURL URLWithString:[[CamFiServerInfo sharedInstance] camfiLiveShowDataUrlString]];
    _photoStreamURLRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.f];
    _photoStreamURLConnection = [NSURLConnection connectionWithRequest:_photoStreamURLRequest delegate:self];
    [_photoStreamURLConnection start];
}

- (void)showPreviewImageData:(NSData*)imgData
{
    UIImage* image = [UIImage imageWithData:_photoData];

    if (image == nil) {
        return;
    }
    else {
        [_previewImageView setImage:image];
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if ([httpResponse statusCode] == 200) {
        skipCount = -1;
        _metaDataStartIndex = 0;
    }
    else {

        AFLogDebug(@"%@", @"camfi.live.show.failed");
        [self stopLiveShow];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    Byte* dataBytes = (Byte*)[data bytes];
    static Byte liveShowMetaData[512];
    
    NSInteger start = -1;
    NSInteger end = -1;
    for (int i = 0; i < [data length] - 1; i++) {
        if (dataBytes[i] == 0xff) { // && dataBytes[i + 1] == 0xd8
            if (i != [data length] - 1 && dataBytes[i + 1] == 0xd8) {
                soi = YES;
                start = i;
            }
        }
        
        if (dataBytes[i] == 0xff) { // && dataBytes[i + 1] == 0xd9
            if (i != [data length] - 1 && dataBytes[i + 1] == 0xd9) {
                end = i;
                soi = NO;
                skipCount = 2;
                _metaDataStartIndex = 0;
            }
        }
        
        if (!ISCANONCAMERA && !soi) {
            if (skipCount > 0) {
                skipCount -= 1;
            }
            else {
                if (_metaDataStartIndex < 512 && skipCount == 0) {
                    liveShowMetaData[_metaDataStartIndex] = dataBytes[i];
                    _metaDataStartIndex++;
                }
            }
        }
    }
    
    if (soi && (end == -1 && start == -1)) {
        
        [_photoData appendData:[data subdataWithRange:NSMakeRange(0, [data length])]];
    }
    else if ((start > -1) && (end > -1)) {
        
        [_photoData appendData:[data subdataWithRange:NSMakeRange(0, end + 2)]];
        [self showPreviewImageData:_photoData];
        _photoData = [[NSMutableData alloc] init];
        [_photoData appendData:[data subdataWithRange:NSMakeRange(start, [data length] - start)]];
    }
    else if ((start == -1) && (end > -1)) {
        
        [_photoData appendData:[data subdataWithRange:NSMakeRange(0, end + 2)]];
        [self showPreviewImageData:_photoData];
        _photoData = [[NSMutableData alloc] init];
    }
    else if (soi && (start > -1) && (end == -1)) {
        
        [_photoData appendData:[data subdataWithRange:NSMakeRange(start, [data length] - start)]];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSLog(@"%@", @"connectionDidFinishLoading");
    [self stopLiveShow];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"%@", error);
    [self stopLiveShow];
}

@end
