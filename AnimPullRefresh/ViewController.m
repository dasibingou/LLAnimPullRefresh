//
//  ViewController.m
//  AnimPullRefresh
//
//  Created by linling on 2019/2/11.
//  Copyright © 2019 llmodule. All rights reserved.
//

#import "ViewController.h"

#import "YYImage.h"

#define KScreenWidth  [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height
#define HEXCOLOR(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:1]
#define HEXCOLORA(hex,a) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:a]

#define IS_IPHONEX_SERIES (KScreenHeight >= 812.0f)
/**
 *  系统默认导航栏(44)加状态栏(20)高度
 */
#define NAV_HEIGHT  (IS_IPHONEX_SERIES ?  88 : 64)

#define WEAKSELF __weak typeof(self) weakSelf = self;

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
{
    CGFloat head_w;             //刷新控件宽度
    CGFloat head_h;             //刷新控件高度
    void (^_pullHandler)(id);   //刷新回调
}

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) YYAnimatedImageView *refreshImg;
@property (nonatomic, copy) NSArray *imgArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self createUI];    //添加tableview
    
    //初始化数据
    self.imgArr = [self cdi_imagesWithGif:@"ll_test_refresh"];
    head_h = self.imgArr.count;
    head_h = 140;
    head_w = 160;
    
    //添加刷新控件
    YYImage *image = [YYImage imageNamed:@"ll_test_refresh.gif"];
    YYAnimatedImageView *imageView = [[YYAnimatedImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake((KScreenWidth - head_w)/2, -head_h, head_w, head_h);
    imageView.autoPlayAnimatedImage = NO;
    [self.tableView insertSubview:imageView atIndex:0];
    self.refreshImg = imageView;

//    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
//    [self.tableView addObserver:self forKeyPath:@"contentOffset" options:options context:nil];

    WEAKSELF
    _pullHandler = ^(id result) {
        [weakSelf requestList];
    };

    [self ll_beginRefresh];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    // 这个就算看不见也需要处理
//    CGFloat y = self.tableView.contentOffset.y;
//    DLOG(@"offsetY:%f",y);
//    self.refreshImg.nim_top = -150+fabs(y);
//    CGFloat dis = 150/self.imgArr.count;
//    int yy = abs((int)y);
//    if (y < 0 && yy < 150) {
//        NSInteger index = 150/(150 - yy);
//        self.refreshImg.image = self.imgArr[index];
//
//    }
//
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y;
    NSLog(@"offsetY:%f",y);
    CGFloat dis = head_h/self.imgArr.count;
    int yy = abs((int)y);
    //小于界限高度则计算图片索引，并显示相应图片
    if (y < 0 && yy < head_h) {
        //通过下拉高度获取图片索引
        NSInteger index = yy/dis;
        index = index >= self.imgArr.count ? self.imgArr.count - 1 : index;
        NSLog(@"index:%ld",index);
        [self.refreshImg stopAnimating];
        self.refreshImg.currentAnimatedImageIndex = index;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat y = scrollView.contentOffset.y;
    int yy = abs((int)y);
    //大于等于界限高度则执行刷新
    if (y < 0 && yy >= head_h) {
        [self ll_beginRefresh];
    }
}

//内存释放
- (void)dealloc
{
    self.refreshImg = nil;
    self.imgArr = nil;
//    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - private
- (void)createUI
{
    CGFloat height = KScreenHeight - NAV_HEIGHT;
    
    self.tableView  = [[UITableView alloc] initWithFrame:CGRectMake(0, NAV_HEIGHT, KScreenWidth, height)  style:UITableViewStylePlain];
    self.tableView.estimatedRowHeight =0;
    self.tableView.estimatedSectionHeaderHeight =0;
    self.tableView.estimatedSectionFooterHeight =0;
    self.tableView.backgroundColor  = [UIColor clearColor];
    self.tableView.tableFooterView  = [[UIView alloc] init];
    self.tableView.delegate     = self;
    self.tableView.dataSource   = self;
    self.tableView.separatorColor = HEXCOLOR(0xEDEDED);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:self.tableView];
    
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

//获取gif图片数组
- (NSArray *)cdi_imagesWithGif:(NSString *)gifNameInBoundle {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:gifNameInBoundle withExtension:@"gif"];
    
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)fileUrl, NULL);
    size_t gifCount = CGImageSourceGetCount(gifSource);
    NSMutableArray *frames = [[NSMutableArray alloc]init];
    for (size_t i = 0; i< gifCount; i++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        [frames addObject:image];
        CGImageRelease(imageRef);
    }
    return frames;
}

//开始刷新
- (void)ll_beginRefresh
{
    [UIView animateWithDuration:0.3 animations:^{
        
        // 增加滚动区域top
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.top = self->head_h;
        self.tableView.contentInset = inset;
        // 设置滚动位置
        CGPoint offset = self.tableView.contentOffset;
        offset.y = -self->head_h;
        [self.tableView setContentOffset:offset animated:NO];
        
    } completion:^(BOOL finished) {
        //开始动画
        [self.refreshImg startAnimating];
        self->_pullHandler(self);
    }];
    
}

//结束刷新
- (void)ll_endRefresh
{
    [self.refreshImg startAnimating];
    [UIView animateWithDuration:0.3 animations:^{
        
        // 恢复滚动区域top
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.top = 0;
        self.tableView.contentInset = inset;
        // 设置滚动位置
        CGPoint offset = self.tableView.contentOffset;
        offset.y = 0;
        [self.tableView setContentOffset:offset animated:NO];
        
    } completion:^(BOOL finished) {
        //结束动画
        [self.refreshImg stopAnimating];
    }];
    
}

//执行耗时操作
- (void)requestList
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self ll_endRefresh];
    });
}

#pragma mark - UITableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELL_IDENTIFI"];
    cell.textLabel.text = @"标题";
    return cell;
}

@end
