# LLAnimPullRefresh
iOS 实现下拉刷新gif实时动画效果

最近看到很多app下拉刷新的酷炫效果，图片伴随下拉高度逐帧变化的那种效果。查了很多资料，还是找不到这样的效果demo。。。不过也找到一个通过计算高度画线的线条动画来实现的demo，这个效果也是非常不错的
![Alt](https://upload-images.jianshu.io/upload_images/831181-9b81703fcb5fd5dd.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/272/format/webp#pic_center)
[demo传送门](https://www.jianshu.com/p/8d2eff1dc173)

实现这种效果需要有比较复杂的画线算法，时间成本比较大。于是我自己思考实现了一种更简单的下拉动画效果，实现的总体思路和普通的下拉刷新差不多，先获取gif图所有帧，再在scrollViewDidScroll:回调里进行取帧逻辑。其中会用到ibireme大神的[YYImage](https://github.com/ibireme/YYImage)图像框架，用于gif取帧操作。

一些下拉刷新组件是通过KVO和手势结合来实现的，这样实现更适合组件化，比如MJRefresh。我这边为了图方便就直接通过scrollViewDidScroll:和scrollViewWillEndDragging:回调方法来实现了。核心方法见以下代码

```swift
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
```

最后实现效果
![image](https://github.com/dasibingou/LLAnimPullRefresh/blob/master/ProjectImage/aaa.gif)
[原文](https://blog.csdn.net/lin371800993/article/details/86982513)，觉得不错的话star一下，谢谢~😄
