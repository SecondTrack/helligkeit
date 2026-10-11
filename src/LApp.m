#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <notify.h>
#import "MeshL10n.h"

// Helligkeit dauerhaft machen: SpringBoards eigenen Wert (SBBacklightLevel2) mitschreiben,
// sonst stellt SpringBoard beim Entsperren den alten Wert wieder her.
static void persistBrightness(CGFloat v){
    float f=(float)v;
    CFNumberRef n=CFNumberCreate(NULL,kCFNumberFloatType,&f);
    CFPreferencesSetValue(CFSTR("SBBacklightLevel2"), n, CFSTR("com.apple.springboard"),
                          kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize(CFSTR("com.apple.springboard"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(n) CFRelease(n);
    notify_post("com.apple.springboard.backlightchanged");
}

static UIColor* C(int r,int g,int b){ return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]; }
// Hell & klar (iOS-nativ), Akzent orange
#define BG    C(242,242,247)
#define CARD  [UIColor whiteColor]
#define TRACK C(229,229,234)
#define LINE  C(209,209,214)
#define INK   C(0,0,0)
#define MUT   C(142,142,147)
#define ORG   C(255,149,0)

// ---- einfache Sonnen-Grafik ----
@interface LSun : UIView
@property(nonatomic) CGFloat rays;
@property(nonatomic,strong) UIColor *tint;
@end
@implementation LSun
- (void)drawRect:(CGRect)r {
    CGContextRef c=UIGraphicsGetCurrentContext();
    CGFloat w=self.bounds.size.width, h=self.bounds.size.height, cx=w/2, cy=h/2;
    CGFloat core=MIN(w,h)*0.20;
    UIColor*t=self.tint?:ORG; [t setStroke]; [t setFill];
    CGContextSetLineWidth(c, MAX(1.5, core*0.28));
    CGContextSetLineCap(c, kCGLineCapRound);
    CGContextFillEllipseInRect(c, CGRectMake(cx-core, cy-core, core*2, core*2));
    int n=8; CGFloat inner=core*1.7, outer=inner + MIN(w,h)*0.14*(0.4+0.6*self.rays);
    for(int i=0;i<n;i++){
        CGFloat a=(M_PI*2.0/n)*i;
        CGContextMoveToPoint(c, cx+cos(a)*inner, cy+sin(a)*inner);
        CGContextAddLineToPoint(c, cx+cos(a)*outer, cy+sin(a)*outer);
    }
    CGContextStrokePath(c);
}
@end

@interface LViewController : UIViewController
@end
@implementation LViewController {
    UILabel *_pct, *_hint;
    UISlider *_sl;
    LSun *_sunR;
    NSArray *_presetBtns;
}

- (void)loadView {
    self.view=[[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor=BG;
    CGFloat W=self.view.bounds.size.width;

    UILabel*title=[[UILabel alloc] initWithFrame:CGRectMake(0,16,W,24)];
    title.text=L(@"Brightness"); title.font=[UIFont boldSystemFontOfSize:16]; title.textColor=MUT;
    title.textAlignment=NSTextAlignmentCenter; title.backgroundColor=[UIColor clearColor]; [self.view addSubview:title];

    _sunR=[[LSun alloc] initWithFrame:CGRectMake(W/2-60,60,120,120)];
    _sunR.backgroundColor=[UIColor clearColor]; _sunR.tint=ORG; _sunR.rays=0.5; [self.view addSubview:_sunR];

    _pct=[[UILabel alloc] initWithFrame:CGRectMake(0,192,W,54)];
    _pct.font=[UIFont boldSystemFontOfSize:50]; _pct.textColor=INK; _pct.textAlignment=NSTextAlignmentCenter;
    _pct.backgroundColor=[UIColor clearColor]; [self.view addSubview:_pct];

    // Slider-Karte
    CGFloat cardY=262, cardH=72;
    UIView*card=[[UIView alloc] initWithFrame:CGRectMake(16,cardY,W-32,cardH)];
    card.backgroundColor=CARD; card.layer.cornerRadius=14; card.layer.borderWidth=0.5; card.layer.borderColor=LINE.CGColor; [self.view addSubview:card];

    LSun*small=[[LSun alloc] initWithFrame:CGRectMake(12,cardH/2-13,26,26)];
    small.backgroundColor=[UIColor clearColor]; small.tint=MUT; small.rays=0.0; [card addSubview:small];
    LSun*big=[[LSun alloc] initWithFrame:CGRectMake(card.bounds.size.width-40,cardH/2-15,30,30)];
    big.backgroundColor=[UIColor clearColor]; big.tint=ORG; big.rays=1.0; [card addSubview:big];

    _sl=[[UISlider alloc] initWithFrame:CGRectMake(48,cardH/2-16,card.bounds.size.width-96,32)];
    _sl.minimumValue=0.0; _sl.maximumValue=1.0;
    _sl.minimumTrackTintColor=ORG; _sl.maximumTrackTintColor=TRACK;
    [_sl addTarget:self action:@selector(slide:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:_sl];

    // Presets
    NSArray*vals=@[@10,@30,@60,@100];
    CGFloat bw=(W-32-30)/4.0, bx=16, by=cardY+cardH+20;
    NSMutableArray*bs=[NSMutableArray array];
    for(int i=0;i<4;i++){
        UIButton*b=[UIButton buttonWithType:UIButtonTypeCustom];
        b.frame=CGRectMake(bx+i*(bw+10), by, bw, 48);
        b.backgroundColor=CARD; b.layer.cornerRadius=12; b.layer.borderWidth=0.5; b.layer.borderColor=LINE.CGColor;
        [b setTitle:[NSString stringWithFormat:@"%@%%",vals[i]] forState:UIControlStateNormal];
        [b setTitleColor:INK forState:UIControlStateNormal];
        b.titleLabel.font=[UIFont boldSystemFontOfSize:15];
        b.tag=[vals[i] intValue];
        [b addTarget:self action:@selector(preset:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:b]; [bs addObject:b];
    }
    _presetBtns=bs;

    _hint=[[UILabel alloc] initWithFrame:CGRectMake(24,by+66,W-48,36)];
    _hint.numberOfLines=0; _hint.font=[UIFont systemFontOfSize:12]; _hint.textColor=MUT;
    _hint.textAlignment=NSTextAlignmentCenter; _hint.backgroundColor=[UIColor clearColor];
    _hint.text=L(@"Sets the system brightness directly — stays after closing.");
    [self.view addSubview:_hint];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _sl.value=[UIScreen mainScreen].brightness;
    [self apply:_sl.value commit:NO];
}

- (void)slide:(UISlider *)s { [self apply:s.value commit:YES]; }

- (void)preset:(UIButton *)b {
    CGFloat v=b.tag/100.0;
    [_sl setValue:v animated:YES];
    [self apply:v commit:YES];
}

- (void)apply:(CGFloat)v commit:(BOOL)commit {
    if(commit){ @try { [UIScreen mainScreen].brightness=v; persistBrightness(v);
        [[NSString stringWithFormat:@"%.3f",(float)v] writeToFile:@"/var/mobile/.brightness" atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    } @catch(__unused id e){} }
    int ip=(int)(v*100.0+0.5);
    _pct.text=[NSString stringWithFormat:@"%d%%",ip];
    _sunR.rays=v; [_sunR setNeedsDisplay];
    for(UIButton*b in _presetBtns){
        BOOL on=(abs((int)b.tag-ip)<=1);
        b.backgroundColor=on?ORG:CARD;
        [b setTitleColor:on?[UIColor whiteColor]:INK forState:UIControlStateNormal];
    }
}
@end

@interface LAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation LAppDelegate
- (BOOL)application:(UIApplication *)a didFinishLaunchingWithOptions:(NSDictionary *)o {
    [a setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController=[[LViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
