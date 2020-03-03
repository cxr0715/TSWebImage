//
//  TSImageHelp.h
//  ImageDemo
//
//  Created by YYInc on 2019/4/9.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, TSImageType) {
    TSImageTypeUnknown = 0, ///< unknown
    TSImageTypeJPEG,        ///< jpeg, jpg
    TSImageTypeJPEG2000,    ///< jp2
    TSImageTypeTIFF,        ///< tiff, tif
    TSImageTypeBMP,         ///< bmp
    TSImageTypeICO,         ///< ico
    TSImageTypeICNS,        ///< icns
    TSImageTypeGIF,         ///< gif
    TSImageTypePNG,         ///< png
    TSImageTypeWebP,        ///< webp
    TSImageTypeOther,       ///< other image format
};

/**
 Dispose method specifies how the area used by the current frame is to be treated
 before rendering the next frame on the canvas.
 */
typedef NS_ENUM(NSUInteger, YYImageDisposeMethod) {
    
    /**
     No disposal is done on this frame before rendering the next; the contents
     of the canvas are left as is.
     */
    YYImageDisposeNone = 0,
    
    /**
     The frame's region of the canvas is to be cleared to fully transparent black
     before rendering the next frame.
     */
    YYImageDisposeBackground,
    
    /**
     The frame's region of the canvas is to be reverted to the previous contents
     before rendering the next frame.
     */
    YYImageDisposePrevious,
};

/**
 Blend operation specifies how transparent pixels of the current frame are
 blended with those of the previous canvas.
 */
typedef NS_ENUM(NSUInteger, YYImageBlendOperation) {
    
    /**
     All color components of the frame, including alpha, overwrite the current
     contents of the frame's canvas region.
     */
    YYImageBlendNone = 0,
    
    /**
     The frame should be composited onto the output buffer based on its alpha.
     */
    YYImageBlendOver,
};

/**
 An image frame object.
 */
@interface YYImageFrame : NSObject <NSCopying>
@property (nonatomic) NSUInteger index;    ///< Frame index (zero based)
@property (nonatomic) NSUInteger width;    ///< Frame width
@property (nonatomic) NSUInteger height;   ///< Frame height
@property (nonatomic) NSUInteger offsetX;  ///< Frame origin.x in canvas (left-bottom based)
@property (nonatomic) NSUInteger offsetY;  ///< Frame origin.y in canvas (left-bottom based)
@property (nonatomic) NSTimeInterval duration;          ///< Frame duration in seconds
@property (nonatomic) YYImageDisposeMethod dispose;     ///< Frame dispose method.
@property (nonatomic) YYImageBlendOperation blend;      ///< Frame blend operation.
@property (nullable, nonatomic, strong) UIImage *image; ///< The image.
+ (instancetype)frameWithImage:(UIImage *)image;
@end

@interface TSImageHelp : NSObject
@property (nullable, nonatomic, readonly) NSData *data;    ///< Image data.
@property (nonatomic, readonly) TSImageType type;          ///< Image data type.
@property (nonatomic, readonly) CGFloat scale;             ///< Image scale.
@property (nonatomic, readonly) NSUInteger frameCount;     ///< Image frame count.
@property (nonatomic, readonly) NSUInteger loopCount;      ///< Image loop count, 0 means infinite.
@property (nonatomic, readonly) NSUInteger width;          ///< Image canvas width.
@property (nonatomic, readonly) NSUInteger height;         ///< Image canvas height.
@property (nonatomic, readonly, getter=isFinalized) BOOL finalized;
- (instancetype)initWithScale:(CGFloat)scale;
- (nullable YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay;
- (void)updateData:(NSData *)data finish:(BOOL)finish;
@end

#pragma mark - UIImage

@interface UIImage (YYImageCoder)

/**
 Decompress this image to bitmap, so when the image is displayed on screen,
 the main thread won't be blocked by additional decode. If the image has already
 been decoded or unable to decode, it just returns itself.
 
 @return an image decoded, or just return itself if no needed.
 @see yy_isDecodedForDisplay
 */
- (instancetype)yy_imageByDecoded;

/**
 Wherher the image can be display on screen without additional decoding.
 @warning It just a hint for your code, change it has no other effect.
 */
@property (nonatomic) BOOL yy_isDecodedForDisplay;

/**
 Saves this image to iOS Photos Album.
 
 @discussion  This method attempts to save the original data to album if the
 image is created from an animated GIF/APNG, otherwise, it will save the image
 as JPEG or PNG (based on the alpha information).
 
 @param completionBlock The block invoked (in main thread) after the save operation completes.
 assetURL: An URL that identifies the saved image file. If the image is not saved, assetURL is nil.
 error: If the image is not saved, an error object that describes the reason for failure, otherwise nil.
 */
- (void)yy_saveToAlbumWithCompletionBlock:(nullable void(^)(NSURL * _Nullable assetURL, NSError * _Nullable error))completionBlock;

/**
 Return a 'best' data representation for this image.
 
 @discussion The convertion based on these rule:
 1. If the image is created from an animated GIF/APNG/WebP, it returns the original data.
 2. It returns PNG or JPEG(0.9) representation based on the alpha information.
 
 @return Image data, or nil if an error occurs.
 */
- (nullable NSData *)yy_imageDataRepresentation;

@end

NS_ASSUME_NONNULL_END
