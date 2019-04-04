//
//  ViewController.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/2.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    CGImageSourceRef _source;
}
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UISlider *slider;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.imageView = [[UIImageView alloc] init];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y, 300, 300);
    self.imageView.center = CGPointMake(self.view.frame.size.width / 2, 50);
    [self.view addSubview:self.imageView];
    
    self.slider = [[UISlider alloc] init];
    [self.slider sizeToFit];
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1.0;
    self.slider.value = 0;
    self.slider.center = CGPointMake(self.view.frame.size.width / 2, self.imageView.center.y);
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y + self.imageView.frame.size.height + 10, 300, 300);
    [self.slider addTarget:self action:@selector(change) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];
}

- (void)change {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mew_baseline.jpg" ofType:@""];
    if (!path) {
        NSLog(@"path nil");
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        NSLog(@"data nil");
    }
    float sliderProgress = self.slider.value;
    if (sliderProgress > 1) {
        sliderProgress = 1;
    }
    
    __block CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
    __weak typeof(self) weakSelf = self;
    dispatch_block_t taskBlock = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSData *subData = [data subdataWithRange:NSMakeRange(0, data.length * sliderProgress)];
        
        strongSelf->_source = CGImageSourceCreateIncremental(NULL);
        if (strongSelf->_source) {
            CGImageSourceUpdateData(strongSelf->_source, (__bridge CFDataRef)subData, false);
        }
        
        if (imageRef) {
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
            CFRelease(context);
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), taskBlock);
    dispatch_block_notify(taskBlock, dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        weakSelf.imageView.image = image;
    });
    
}


@end
