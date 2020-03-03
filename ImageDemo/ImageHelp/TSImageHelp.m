//
//  TSImageHelp.m
//  ImageDemo
//
//  Created by YYInc on 2019/4/9.
//  Copyright © 2019年 caoxuerui. All rights reserved.
//

#import "TSImageHelp.h"
#import <ImageIO/ImageIO.h>
#import "NSArray+ThreadSafe.h"
#import <objc/runtime.h>
#import <zlib.h>

#define TS_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define TS_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

static inline uint16_t yy_swap_endian_uint16(uint16_t value) {
    return
    (uint16_t) ((value & 0x00FF) << 8) |
    (uint16_t) ((value & 0xFF00) >> 8) ;
}

static inline uint32_t yy_swap_endian_uint32(uint32_t value) {
    return
    (uint32_t)((value & 0x000000FFU) << 24) |
    (uint32_t)((value & 0x0000FF00U) <<  8) |
    (uint32_t)((value & 0x00FF0000U) >>  8) |
    (uint32_t)((value & 0xFF000000U) >> 24) ;
}

static void YYCGDataProviderReleaseDataCallback(void *info, const void *data, size_t size) {
    if (info) free(info);
}

typedef enum {
    YY_PNG_DISPOSE_OP_NONE = 0,
    YY_PNG_DISPOSE_OP_BACKGROUND = 1,
    YY_PNG_DISPOSE_OP_PREVIOUS = 2,
} yy_png_dispose_op;

typedef enum {
    YY_PNG_BLEND_OP_SOURCE = 0,
    YY_PNG_BLEND_OP_OVER = 1,
} yy_png_blend_op;

typedef struct {
    uint32_t width;             ///< pixel count, should not be zero
    uint32_t height;            ///< pixel count, should not be zero
    uint8_t bit_depth;          ///< expected: 1, 2, 4, 8, 16
    uint8_t color_type;         ///< see yy_png_alpha_type
    uint8_t compression_method; ///< 0 (deflate/inflate)
    uint8_t filter_method;      ///< 0 (adaptive filtering with five basic filter types)
    uint8_t interlace_method;   ///< 0 (no interlace) or 1 (Adam7 interlace)
} yy_png_chunk_IHDR;

typedef struct {
    uint32_t sequence_number;  ///< sequence number of the animation chunk, starting from 0
    uint32_t width;            ///< width of the following frame
    uint32_t height;           ///< height of the following frame
    uint32_t x_offset;         ///< x position at which to render the following frame
    uint32_t y_offset;         ///< y position at which to render the following frame
    uint16_t delay_num;        ///< frame delay fraction numerator
    uint16_t delay_den;        ///< frame delay fraction denominator
    uint8_t dispose_op;        ///< see yy_png_dispose_op
    uint8_t blend_op;          ///< see yy_png_blend_op
} yy_png_chunk_fcTL;

typedef struct {
    uint32_t offset; ///< chunk offset in PNG data
    uint32_t fourcc; ///< chunk fourcc
    uint32_t length; ///< chunk data length
    uint32_t crc32;  ///< chunk crc32
} yy_png_chunk_info;

typedef struct {
    uint32_t chunk_index; ///< the first `fdAT`/`IDAT` chunk index
    uint32_t chunk_num;   ///< the `fdAT`/`IDAT` chunk count
    uint32_t chunk_size;  ///< the `fdAT`/`IDAT` chunk bytes
    yy_png_chunk_fcTL frame_control;
} yy_png_frame_info;

typedef struct {
    yy_png_chunk_IHDR header;   ///< png header
    yy_png_chunk_info *chunks;      ///< chunks
    uint32_t chunk_num;          ///< count of chunks
    
    yy_png_frame_info *apng_frames; ///< frame info, NULL if not apng
    uint32_t apng_frame_num;     ///< 0 if not apng
    uint32_t apng_loop_num;      ///< 0 indicates infinite looping
    
    uint32_t *apng_shared_chunk_indexs; ///< shared chunk index
    uint32_t apng_shared_chunk_num;     ///< shared chunk count
    uint32_t apng_shared_chunk_size;    ///< shared chunk bytes
    uint32_t apng_shared_insert_index;  ///< shared chunk insert index
    bool apng_first_frame_is_cover;     ///< the first frame is same as png (cover)
} yy_png_info;

static void yy_png_chunk_fcTL_read(yy_png_chunk_fcTL *fcTL, const uint8_t *data) {
    fcTL->sequence_number = yy_swap_endian_uint32(*((uint32_t *)(data)));
    fcTL->width = yy_swap_endian_uint32(*((uint32_t *)(data + 4)));
    fcTL->height = yy_swap_endian_uint32(*((uint32_t *)(data + 8)));
    fcTL->x_offset = yy_swap_endian_uint32(*((uint32_t *)(data + 12)));
    fcTL->y_offset = yy_swap_endian_uint32(*((uint32_t *)(data + 16)));
    fcTL->delay_num = yy_swap_endian_uint16(*((uint16_t *)(data + 20)));
    fcTL->delay_den = yy_swap_endian_uint16(*((uint16_t *)(data + 22)));
    fcTL->dispose_op = data[24];
    fcTL->blend_op = data[25];
}

static void yy_png_chunk_IHDR_write(yy_png_chunk_IHDR *IHDR, uint8_t *data) {
    *((uint32_t *)(data)) = yy_swap_endian_uint32(IHDR->width);
    *((uint32_t *)(data + 4)) = yy_swap_endian_uint32(IHDR->height);
    data[8] = IHDR->bit_depth;
    data[9] = IHDR->color_type;
    data[10] = IHDR->compression_method;
    data[11] = IHDR->filter_method;
    data[12] = IHDR->interlace_method;
}

static void yy_png_chunk_IHDR_read(yy_png_chunk_IHDR *IHDR, const uint8_t *data) {
    IHDR->width = yy_swap_endian_uint32(*((uint32_t *)(data)));
    IHDR->height = yy_swap_endian_uint32(*((uint32_t *)(data + 4)));
    IHDR->bit_depth = data[8];
    IHDR->color_type = data[9];
    IHDR->compression_method = data[10];
    IHDR->filter_method = data[11];
    IHDR->interlace_method = data[12];
}

static double yy_png_delay_to_seconds(uint16_t num, uint16_t den) {
    if (den == 0) {
        return num / 100.0;
    } else {
        return (double)num / (double)den;
    }
}

static bool yy_png_validate_animation_chunk_order(yy_png_chunk_info *chunks,  /* input */
                                                  uint32_t chunk_num,         /* input */
                                                  uint32_t *first_idat_index, /* output */
                                                  bool *first_frame_is_cover  /* output */) {
    /*
     PNG at least contains 3 chunks: IHDR, IDAT, IEND.
     `IHDR` must appear first.
     `IDAT` must appear consecutively.
     `IEND` must appear end.
     
     APNG must contains one `acTL` and at least one 'fcTL' and `fdAT`.
     `fdAT` must appear consecutively.
     `fcTL` must appear before `IDAT` or `fdAT`.
     */
    if (chunk_num <= 2) return false;
    if (chunks->fourcc != TS_FOUR_CC('I', 'H', 'D', 'R')) return false;
    if ((chunks + chunk_num - 1)->fourcc != TS_FOUR_CC('I', 'E', 'N', 'D')) return false;
    
    uint32_t prev_fourcc = 0;
    uint32_t IHDR_num = 0;
    uint32_t IDAT_num = 0;
    uint32_t acTL_num = 0;
    uint32_t fcTL_num = 0;
    uint32_t first_IDAT = 0;
    bool first_frame_cover = false;
    for (uint32_t i = 0; i < chunk_num; i++) {
        yy_png_chunk_info *chunk = chunks + i;
        switch (chunk->fourcc) {
            case TS_FOUR_CC('I', 'H', 'D', 'R'): {  // png header
                if (i != 0) return false;
                if (IHDR_num > 0) return false;
                IHDR_num++;
            } break;
            case TS_FOUR_CC('I', 'D', 'A', 'T'): {  // png data
                if (prev_fourcc != TS_FOUR_CC('I', 'D', 'A', 'T')) {
                    if (IDAT_num == 0)
                        first_IDAT = i;
                    else
                        return false;
                }
                IDAT_num++;
            } break;
            case TS_FOUR_CC('a', 'c', 'T', 'L'): {  // apng control
                if (acTL_num > 0) return false;
                acTL_num++;
            } break;
            case TS_FOUR_CC('f', 'c', 'T', 'L'): {  // apng frame control
                if (i + 1 == chunk_num) return false;
                if ((chunk + 1)->fourcc != TS_FOUR_CC('f', 'd', 'A', 'T') &&
                    (chunk + 1)->fourcc != TS_FOUR_CC('I', 'D', 'A', 'T')) {
                    return false;
                }
                if (fcTL_num == 0) {
                    if ((chunk + 1)->fourcc == TS_FOUR_CC('I', 'D', 'A', 'T')) {
                        first_frame_cover = true;
                    }
                }
                fcTL_num++;
            } break;
            case TS_FOUR_CC('f', 'd', 'A', 'T'): {  // apng data
                if (prev_fourcc != TS_FOUR_CC('f', 'd', 'A', 'T') && prev_fourcc != TS_FOUR_CC('f', 'c', 'T', 'L')) {
                    return false;
                }
            } break;
        }
        prev_fourcc = chunk->fourcc;
    }
    if (IHDR_num != 1) return false;
    if (IDAT_num == 0) return false;
    if (acTL_num != 1) return false;
    if (fcTL_num < acTL_num) return false;
    *first_idat_index = first_IDAT;
    *first_frame_is_cover = first_frame_cover;
    return true;
}

static void yy_png_info_release(yy_png_info *info) {
    if (info) {
        if (info->chunks) free(info->chunks);
        if (info->apng_frames) free(info->apng_frames);
        if (info->apng_shared_chunk_indexs) free(info->apng_shared_chunk_indexs);
        free(info);
    }
}

static yy_png_info *yy_png_info_create(const uint8_t *data, uint32_t length) {
    if (length < 32) return NULL;
    if (*((uint32_t *)data) != TS_FOUR_CC(0x89, 0x50, 0x4E, 0x47)) return NULL;
    if (*((uint32_t *)(data + 4)) != TS_FOUR_CC(0x0D, 0x0A, 0x1A, 0x0A)) return NULL;
    
    uint32_t chunk_realloc_num = 16;
    yy_png_chunk_info *chunks = malloc(sizeof(yy_png_chunk_info) * chunk_realloc_num);
    if (!chunks) return NULL;
    
    // parse png chunks
    uint32_t offset = 8;
    uint32_t chunk_num = 0;
    uint32_t chunk_capacity = chunk_realloc_num;
    uint32_t apng_loop_num = 0;
    int32_t apng_sequence_index = -1;
    int32_t apng_frame_index = 0;
    int32_t apng_frame_number = -1;
    bool apng_chunk_error = false;
    do {
        if (chunk_num >= chunk_capacity) {
            yy_png_chunk_info *new_chunks = realloc(chunks, sizeof(yy_png_chunk_info) * (chunk_capacity + chunk_realloc_num));
            if (!new_chunks) {
                free(chunks);
                return NULL;
            }
            chunks = new_chunks;
            chunk_capacity += chunk_realloc_num;
        }
        yy_png_chunk_info *chunk = chunks + chunk_num;
        const uint8_t *chunk_data = data + offset;
        chunk->offset = offset;
        chunk->length = yy_swap_endian_uint32(*((uint32_t *)chunk_data));
        if ((uint64_t)chunk->offset + (uint64_t)chunk->length + 12 > length) {
            free(chunks);
            return NULL;
        }
        
        chunk->fourcc = *((uint32_t *)(chunk_data + 4));
        if ((uint64_t)chunk->offset + 4 + chunk->length + 4 > (uint64_t)length) break;
        chunk->crc32 = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8 + chunk->length)));
        chunk_num++;
        offset += 12 + chunk->length;
        
        switch (chunk->fourcc) {
            case TS_FOUR_CC('a', 'c', 'T', 'L') : {
                if (chunk->length == 8) {
                    apng_frame_number = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8)));
                    apng_loop_num = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 12)));
                } else {
                    apng_chunk_error = true;
                }
            } break;
            case TS_FOUR_CC('f', 'c', 'T', 'L') :
            case TS_FOUR_CC('f', 'd', 'A', 'T') : {
                if (chunk->fourcc == TS_FOUR_CC('f', 'c', 'T', 'L')) {
                    if (chunk->length != 26) {
                        apng_chunk_error = true;
                    } else {
                        apng_frame_index++;
                    }
                }
                if (chunk->length > 4) {
                    uint32_t sequence = yy_swap_endian_uint32(*((uint32_t *)(chunk_data + 8)));
                    if (apng_sequence_index + 1 == sequence) {
                        apng_sequence_index++;
                    } else {
                        apng_chunk_error = true;
                    }
                } else {
                    apng_chunk_error = true;
                }
            } break;
            case TS_FOUR_CC('I', 'E', 'N', 'D') : {
                offset = length; // end, break do-while loop
            } break;
        }
    } while (offset + 12 <= length);
    
    if (chunk_num < 3 ||
        chunks->fourcc != TS_FOUR_CC('I', 'H', 'D', 'R') ||
        chunks->length != 13) {
        free(chunks);
        return NULL;
    }
    
    // png info
    yy_png_info *info = calloc(1, sizeof(yy_png_info));
    if (!info) {
        free(chunks);
        return NULL;
    }
    info->chunks = chunks;
    info->chunk_num = chunk_num;
    yy_png_chunk_IHDR_read(&info->header, data + chunks->offset + 8);
    
    // apng info
    if (!apng_chunk_error && apng_frame_number == apng_frame_index && apng_frame_number >= 1) {
        bool first_frame_is_cover = false;
        uint32_t first_IDAT_index = 0;
        if (!yy_png_validate_animation_chunk_order(info->chunks, info->chunk_num, &first_IDAT_index, &first_frame_is_cover)) {
            return info; // ignore apng chunk
        }
        
        info->apng_loop_num = apng_loop_num;
        info->apng_frame_num = apng_frame_number;
        info->apng_first_frame_is_cover = first_frame_is_cover;
        info->apng_shared_insert_index = first_IDAT_index;
        info->apng_frames = calloc(apng_frame_number, sizeof(yy_png_frame_info));
        if (!info->apng_frames) {
            yy_png_info_release(info);
            return NULL;
        }
        info->apng_shared_chunk_indexs = calloc(info->chunk_num, sizeof(uint32_t));
        if (!info->apng_shared_chunk_indexs) {
            yy_png_info_release(info);
            return NULL;
        }
        
        int32_t frame_index = -1;
        uint32_t *shared_chunk_index = info->apng_shared_chunk_indexs;
        for (int32_t i = 0; i < info->chunk_num; i++) {
            yy_png_chunk_info *chunk = info->chunks + i;
            switch (chunk->fourcc) {
                case TS_FOUR_CC('I', 'D', 'A', 'T'): {
                    if (info->apng_shared_insert_index == 0) {
                        info->apng_shared_insert_index = i;
                    }
                    if (first_frame_is_cover) {
                        yy_png_frame_info *frame = info->apng_frames + frame_index;
                        frame->chunk_num++;
                        frame->chunk_size += chunk->length + 12;
                    }
                } break;
                case TS_FOUR_CC('a', 'c', 'T', 'L'): {
                } break;
                case TS_FOUR_CC('f', 'c', 'T', 'L'): {
                    frame_index++;
                    yy_png_frame_info *frame = info->apng_frames + frame_index;
                    frame->chunk_index = i + 1;
                    yy_png_chunk_fcTL_read(&frame->frame_control, data + chunk->offset + 8);
                } break;
                case TS_FOUR_CC('f', 'd', 'A', 'T'): {
                    yy_png_frame_info *frame = info->apng_frames + frame_index;
                    frame->chunk_num++;
                    frame->chunk_size += chunk->length + 12;
                } break;
                default: {
                    *shared_chunk_index = i;
                    shared_chunk_index++;
                    info->apng_shared_chunk_size += chunk->length + 12;
                    info->apng_shared_chunk_num++;
                } break;
            }
        }
    }
    return info;
}

static uint8_t *yy_png_copy_frame_data_at_index(const uint8_t *data,
                                                const yy_png_info *info,
                                                const uint32_t index,
                                                uint32_t *size) {
    if (index >= info->apng_frame_num) return NULL;
    
    yy_png_frame_info *frame_info = info->apng_frames + index;
    uint32_t frame_remux_size = 8 /* PNG Header */ + info->apng_shared_chunk_size + frame_info->chunk_size;
    if (!(info->apng_first_frame_is_cover && index == 0)) {
        frame_remux_size -= frame_info->chunk_num * 4; // remove fdAT sequence number
    }
    uint8_t *frame_data = malloc(frame_remux_size);
    if (!frame_data) return NULL;
    *size = frame_remux_size;
    
    uint32_t data_offset = 0;
    bool inserted = false;
    memcpy(frame_data, data, 8); // PNG File Header
    data_offset += 8;
    for (uint32_t i = 0; i < info->apng_shared_chunk_num; i++) {
        uint32_t shared_chunk_index = info->apng_shared_chunk_indexs[i];
        yy_png_chunk_info *shared_chunk_info = info->chunks + shared_chunk_index;
        
        if (shared_chunk_index >= info->apng_shared_insert_index && !inserted) { // replace IDAT with fdAT
            inserted = true;
            for (uint32_t c = 0; c < frame_info->chunk_num; c++) {
                yy_png_chunk_info *insert_chunk_info = info->chunks + frame_info->chunk_index + c;
                if (insert_chunk_info->fourcc == TS_FOUR_CC('f', 'd', 'A', 'T')) {
                    *((uint32_t *)(frame_data + data_offset)) = yy_swap_endian_uint32(insert_chunk_info->length - 4);
                    *((uint32_t *)(frame_data + data_offset + 4)) = TS_FOUR_CC('I', 'D', 'A', 'T');
                    memcpy(frame_data + data_offset + 8, data + insert_chunk_info->offset + 12, insert_chunk_info->length - 4);
                    uint32_t crc = (uint32_t)crc32(0, frame_data + data_offset + 4, insert_chunk_info->length);
                    *((uint32_t *)(frame_data + data_offset + insert_chunk_info->length + 4)) = yy_swap_endian_uint32(crc);
                    data_offset += insert_chunk_info->length + 8;
                } else { // IDAT
                    memcpy(frame_data + data_offset, data + insert_chunk_info->offset, insert_chunk_info->length + 12);
                    data_offset += insert_chunk_info->length + 12;
                }
            }
        }
        
        if (shared_chunk_info->fourcc == TS_FOUR_CC('I', 'H', 'D', 'R')) {
            uint8_t tmp[25] = {0};
            memcpy(tmp, data + shared_chunk_info->offset, 25);
            yy_png_chunk_IHDR IHDR = info->header;
            IHDR.width = frame_info->frame_control.width;
            IHDR.height = frame_info->frame_control.height;
            yy_png_chunk_IHDR_write(&IHDR, tmp + 8);
            *((uint32_t *)(tmp + 21)) = yy_swap_endian_uint32((uint32_t)crc32(0, tmp + 4, 17));
            memcpy(frame_data + data_offset, tmp, 25);
            data_offset += 25;
        } else {
            memcpy(frame_data + data_offset, data + shared_chunk_info->offset, shared_chunk_info->length + 12);
            data_offset += shared_chunk_info->length + 12;
        }
    }
    return frame_data;
}

UIImageOrientation YYUIImageOrientationFromEXIFValue(NSInteger value) {
    switch (value) {
        case kCGImagePropertyOrientationUp: return UIImageOrientationUp;
        case kCGImagePropertyOrientationDown: return UIImageOrientationDown;
        case kCGImagePropertyOrientationLeft: return UIImageOrientationLeft;
        case kCGImagePropertyOrientationRight: return UIImageOrientationRight;
        case kCGImagePropertyOrientationUpMirrored: return UIImageOrientationUpMirrored;
        case kCGImagePropertyOrientationDownMirrored: return UIImageOrientationDownMirrored;
        case kCGImagePropertyOrientationLeftMirrored: return UIImageOrientationLeftMirrored;
        case kCGImagePropertyOrientationRightMirrored: return UIImageOrientationRightMirrored;
        default: return UIImageOrientationUp;
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Decoder

@implementation YYImageFrame
+ (instancetype)frameWithImage:(UIImage *)image {
    YYImageFrame *frame = [self new];
    frame.image = image;
    return frame;
}
- (id)copyWithZone:(NSZone *)zone {
    YYImageFrame *frame = [self.class new];
    frame.index = _index;
    frame.width = _width;
    frame.height = _height;
    frame.offsetX = _offsetX;
    frame.offsetY = _offsetY;
    frame.duration = _duration;
    frame.dispose = _dispose;
    frame.blend = _blend;
    frame.image = _image.copy;
    return frame;
}
@end

// Internal frame object.
@interface _YYImageDecoderFrame : YYImageFrame
@property (nonatomic, assign) BOOL hasAlpha;                ///< Whether frame has alpha.
@property (nonatomic, assign) BOOL isFullSize;              ///< Whether frame fill the canvas.
@property (nonatomic, assign) NSUInteger blendFromIndex;    ///< Blend from frame index to current frame.
@end

@implementation _YYImageDecoderFrame
- (id)copyWithZone:(NSZone *)zone {
    _YYImageDecoderFrame *frame = [super copyWithZone:zone];
    frame.hasAlpha = _hasAlpha;
    frame.isFullSize = _isFullSize;
    frame.blendFromIndex = _blendFromIndex;
    return frame;
}
@end

@implementation TSImageHelp {
    CGImageSourceRef _source;
    yy_png_info *_apngSource;
    UIImageOrientation _orientation;
    NSArray *_frames; ///< Array<GGImageDecoderFrame>, without image
    BOOL _needBlend;
    NSUInteger _blendFrameIndex;
    CGContextRef _blendCanvas;
}

- (instancetype)initWithScale:(CGFloat)scale {
    self = [super init];
    if (scale <= 0) scale = 1;
    _scale = scale;
//    _framesLock = dispatch_semaphore_create(1);
    
//    pthread_mutexattr_t attr;
//    pthread_mutexattr_init (&attr);
//    pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
//    pthread_mutex_init (&_lock, &attr);
//    pthread_mutexattr_destroy (&attr);
    
    return self;
}

- (YYImageFrame *)frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    YYImageFrame *result = nil;
    result = [self _frameAtIndex:index decodeForDisplay:decodeForDisplay];
    return result;
}

- (YYImageFrame *)_frameAtIndex:(NSUInteger)index decodeForDisplay:(BOOL)decodeForDisplay {
    if (index >= _frames.count) return 0;
    _YYImageDecoderFrame *frame = [(_YYImageDecoderFrame *)_frames[index] copy];
    BOOL decoded = NO;
    BOOL extendToCanvas = NO;
    if (_type != TSImageTypeICO && decodeForDisplay) { // ICO contains multi-size frame and should not extend to canvas.
        extendToCanvas = YES;
    }
    
    if (!_needBlend) {
        CGImageRef imageRef = [self _newUnblendedImageAtIndex:index extendToCanvas:extendToCanvas decoded:&decoded];
        if (!imageRef) return nil;
        if (decodeForDisplay && !decoded) {
            CGImageRef imageRefDecoded = YYCGImageCreateDecodedCopy(imageRef, YES);
            if (imageRefDecoded) {
                CFRelease(imageRef);
                imageRef = imageRefDecoded;
                decoded = YES;
            }
        }
        UIImage *image = [UIImage imageWithCGImage:imageRef scale:_scale orientation:_orientation];
        CFRelease(imageRef);
        if (!image) return nil;
        image.yy_isDecodedForDisplay = decoded;
        frame.image = image;
        return frame;
    }
    
    // blend
    if (![self _createBlendContextIfNeeded]) return nil;
    CGImageRef imageRef = NULL;
    
    if (_blendFrameIndex + 1 == frame.index) {
//        imageRef = [self _newBlendedImageWithFrame:frame];
        _blendFrameIndex = index;
    }
    
#warning mark todo
    return nil;
}

- (void)updateData:(NSData *)data finish:(BOOL)finish {
    TSImageType type = TSImageDetectType((__bridge CFDataRef)data);
    switch (type) {
        case TSImageTypeWebP: {
//            [self _updateSourceWebP];
        } break;
            
        case TSImageTypePNG: {
            [self _updateSourceAPNG];
        } break;
            
        default: {
            [self _updateSourceImageIO];
        } break;
    }
}

- (void)_updateSourceAPNG {
    /*
     APNG extends PNG format to support animation, it was supported by ImageIO
     since iOS 8.
     
     We use a custom APNG decoder to make APNG available in old system, so we
     ignore the ImageIO's APNG frame info. Typically the custom decoder is a bit
     faster than ImageIO.
     */
    
    yy_png_info_release(_apngSource);
    _apngSource = nil;
    
    [self _updateSourceImageIO]; // decode first frame
    if (_frameCount == 0) return; // png decode failed
    if (!_finalized) return; // ignore multi-frame before finalized
    
    yy_png_info *apng = yy_png_info_create(_data.bytes, (uint32_t)_data.length);
    if (!apng) return; // apng decode failed
    if (apng->apng_frame_num == 0 ||
        (apng->apng_frame_num == 1 && apng->apng_first_frame_is_cover)) {
        yy_png_info_release(apng);
        return; // no animation
    }
    if (_source) { // apng decode succeed, no longer need image souce
        CFRelease(_source);
        _source = NULL;
    }
    
    uint32_t canvasWidth = apng->header.width;
    uint32_t canvasHeight = apng->header.height;
    NSMutableArray *frames = [NSMutableArray TsArray];
    BOOL needBlend = NO;
    uint32_t lastBlendIndex = 0;
    for (uint32_t i = 0; i < apng->apng_frame_num; i++) {
        _YYImageDecoderFrame *frame = [_YYImageDecoderFrame new];
        [frames addObject:frame];
        
        yy_png_frame_info *fi = apng->apng_frames + i;
        frame.index = i;
        frame.duration = yy_png_delay_to_seconds(fi->frame_control.delay_num, fi->frame_control.delay_den);
        frame.hasAlpha = YES;
        frame.width = fi->frame_control.width;
        frame.height = fi->frame_control.height;
        frame.offsetX = fi->frame_control.x_offset;
        frame.offsetY = canvasHeight - fi->frame_control.y_offset - fi->frame_control.height;
        
        BOOL sizeEqualsToCanvas = (frame.width == canvasWidth && frame.height == canvasHeight);
        BOOL offsetIsZero = (fi->frame_control.x_offset == 0 && fi->frame_control.y_offset == 0);
        frame.isFullSize = (sizeEqualsToCanvas && offsetIsZero);
        
        switch (fi->frame_control.dispose_op) {
            case YY_PNG_DISPOSE_OP_BACKGROUND: {
                frame.dispose = YYImageDisposeBackground;
            } break;
            case YY_PNG_DISPOSE_OP_PREVIOUS: {
                frame.dispose = YYImageDisposePrevious;
            } break;
            default: {
                frame.dispose = YYImageDisposeNone;
            } break;
        }
        switch (fi->frame_control.blend_op) {
            case YY_PNG_BLEND_OP_OVER: {
                frame.blend = YYImageBlendOver;
            } break;
                
            default: {
                frame.blend = YYImageBlendNone;
            } break;
        }
        
        if (frame.blend == YYImageBlendNone && frame.isFullSize) {
            frame.blendFromIndex  = i;
            if (frame.dispose != YYImageDisposePrevious) lastBlendIndex = i;
        } else {
            if (frame.dispose == YYImageDisposeBackground && frame.isFullSize) {
                frame.blendFromIndex = lastBlendIndex;
                lastBlendIndex = i + 1;
            } else {
                frame.blendFromIndex = lastBlendIndex;
            }
        }
        if (frame.index != frame.blendFromIndex) needBlend = YES;
    }
    
    _width = canvasWidth;
    _height = canvasHeight;
    _frameCount = frames.count;
    _loopCount = apng->apng_loop_num;
    _needBlend = needBlend;
    _apngSource = apng;
    _frames = frames;
}

- (void)_updateSourceImageIO {
    _width = 0;
    _height = 0;
    _orientation = UIImageOrientationUp;
    _loopCount = 0;
    
    _frames = nil;
    
    if (!_source) {
        if (_finalized) {
            _source = CGImageSourceCreateWithData((__bridge CFDataRef)_data, NULL);
        } else {
            _source = CGImageSourceCreateIncremental(NULL);
            if (_source) CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, false);
        }
    } else {
        CGImageSourceUpdateData(_source, (__bridge CFDataRef)_data, _finalized);
    }
    if (!_source) return;

    _frameCount = CGImageSourceGetCount(_source);
    if (_frameCount == 0) return;
    
    if (!_finalized) { // ignore multi-frame before finalized
        _frameCount = 1;
    } else {
        if (_type == TSImageTypePNG) { // use custom apng decoder and ignore multi-frame
            _frameCount = 1;
        }
        if (_type == TSImageTypeGIF) { // get gif loop count
            CFDictionaryRef properties = CGImageSourceCopyProperties(_source, NULL);
            if (properties) {
                CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gif) {
                    CFTypeRef loop = CFDictionaryGetValue(gif, kCGImagePropertyGIFLoopCount);
                    if (loop) CFNumberGetValue(loop, kCFNumberNSIntegerType, &_loopCount);
                }
                CFRelease(properties);
            }
        }
    }
    
    /*
     ICO, GIF, APNG may contains multi-frame.
     */
    NSMutableArray *frames = [NSMutableArray TsArray];
    for (NSUInteger i = 0; i < _frameCount; i++) {
        _YYImageDecoderFrame *frame = [_YYImageDecoderFrame new];
        frame.index = i;
        frame.blendFromIndex = i;
        frame.hasAlpha = YES;
        frame.isFullSize = YES;
        [frames addObject:frame];
        
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_source, i, NULL);
        if (properties) {
            NSTimeInterval duration = 0;
            NSInteger orientationValue = 0, width = 0, height = 0;
            CFTypeRef value = NULL;
            
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &width);
            value = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (value) CFNumberGetValue(value, kCFNumberNSIntegerType, &height);
            if (_type == TSImageTypeGIF) {
                CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gif) {
                    // Use the unclamped frame delay if it exists.
                    value = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                    if (!value) {
                        // Fall back to the clamped frame delay if the unclamped frame delay does not exist.
                        value = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                    }
                    if (value) CFNumberGetValue(value, kCFNumberDoubleType, &duration);
                }
            }
            
            frame.width = width;
            frame.height = height;
            frame.duration = duration;
            
            if (i == 0 && _width + _height == 0) { // init first frame
                _width = width;
                _height = height;
                value = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (value) {
                    CFNumberGetValue(value, kCFNumberNSIntegerType, &orientationValue);
                    _orientation = YYUIImageOrientationFromEXIFValue(orientationValue);
                }
            }
            CFRelease(properties);
        }
    }
    
    _frames = frames;
}

- (CGImageRef)_newUnblendedImageAtIndex:(NSUInteger)index extendToCanvas:(BOOL)extendToCanvas decoded:(BOOL *)decoded CF_RETURNS_RETAINED {
    if (!_finalized && index > 0) return NULL;
    if (_frames.count <= index) return NULL;
    _YYImageDecoderFrame *frame = _frames[index];
    
    if (_source) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_source, index, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
        if (imageRef && extendToCanvas) {
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            if (width == _width && height == _height) {
                CGImageRef imageRefExtended = YYCGImageCreateDecodedCopy(imageRef, YES);
                if (imageRefExtended) {
                    CFRelease(imageRef);
                    imageRef = imageRefExtended;
                    if (decoded) *decoded = YES;
                }
            } else {
                CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
                if (context) {
                    CGContextDrawImage(context, CGRectMake(0, _height - height, width, height), imageRef);
                    CGImageRef imageRefExtended = CGBitmapContextCreateImage(context);
                    CFRelease(context);
                    if (imageRefExtended) {
                        CFRelease(imageRef);
                        imageRef = imageRefExtended;
                        if (decoded) *decoded = YES;
                    }
                }
            }
        }
        return imageRef;
    }
    
    if (_apngSource) {
        uint32_t size = 0;
        uint8_t *bytes = yy_png_copy_frame_data_at_index(_data.bytes, _apngSource, (uint32_t)index, &size);
        if (!bytes) return NULL;
        CGDataProviderRef provider = CGDataProviderCreateWithData(bytes, bytes, size, YYCGDataProviderReleaseDataCallback);
        if (!provider) {
            free(bytes);
            return NULL;
        }
        bytes = NULL; // hold by provider
        
        CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
        if (!source) {
            CFRelease(provider);
            return NULL;
        }
        CFRelease(provider);
        
        if(CGImageSourceGetCount(source) < 1) {
            CFRelease(source);
            return NULL;
        }
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)@{(id)kCGImageSourceShouldCache:@(YES)});
        CFRelease(source);
        if (!imageRef) return NULL;
        if (extendToCanvas) {
            CGContextRef context = CGBitmapContextCreate(NULL, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst); //bgrA
            if (context) {
                CGContextDrawImage(context, CGRectMake(frame.offsetX, frame.offsetY, frame.width, frame.height), imageRef);
                CFRelease(imageRef);
                imageRef = CGBitmapContextCreateImage(context);
                CFRelease(context);
                if (decoded) *decoded = YES;
            }
        }
        return imageRef;
    }
    
    return NULL;
}

- (BOOL)_createBlendContextIfNeeded {
    if (!_blendCanvas) {
        _blendFrameIndex = NSNotFound;
        _blendCanvas = CGBitmapContextCreate(NULL, _width, _height, 8, 0, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    }
    BOOL suc = _blendCanvas != NULL;
    return suc;
}

TSImageType TSImageDetectType(CFDataRef data) {
    if (!data) return TSImageTypeUnknown;
    uint64_t length = CFDataGetLength(data);
    if (length < 16) return TSImageTypeUnknown;
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case TS_FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return TSImageTypeTIFF;
        } break;
            
        case TS_FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return TSImageTypeTIFF;
        } break;
            
        case TS_FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return TSImageTypeICO;
        } break;
            
        case TS_FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return TSImageTypeICO;
        } break;
            
        case TS_FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return TSImageTypeICNS;
        } break;
            
        case TS_FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return TSImageTypeGIF;
        } break;
            
        case TS_FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == TS_FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return TSImageTypePNG;
            }
        } break;
            
        case TS_FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == TS_FOUR_CC('W', 'E', 'B', 'P')) {
                return TSImageTypeWebP;
            }
        } break;
            /*
             case YY_FOUR_CC('B', 'P', 'G', 0xFB): { // BPG
             return YYImageTypeBPG;
             } break;
             */
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case TS_TWO_CC('B', 'A'):
        case TS_TWO_CC('B', 'M'):
        case TS_TWO_CC('I', 'C'):
        case TS_TWO_CC('P', 'I'):
        case TS_TWO_CC('C', 'I'):
        case TS_TWO_CC('C', 'P'): { // BMP
            return TSImageTypeBMP;
        }
        case TS_TWO_CC(0xFF, 0x4F): { // JPEG2000
            return TSImageTypeJPEG2000;
        }
    }
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return TSImageTypeJPEG;
    
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return TSImageTypeJPEG2000;
    
    return TSImageTypeUnknown;
}

CGImageRef YYCGImageCreateDecodedCopy(CGImageRef imageRef, BOOL decodeForDisplay) {
    if (!imageRef) return NULL;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || height == 0) return NULL;
    
    if (decodeForDisplay) { //decode with redraw (may lose some precision)
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha = NO;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = YES;
        }
        // BGRA8888 (premultiplied) or BGRX8888
        // same as UIGraphicsBeginImageContext() and -[UIView drawRect:]
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo);
        if (!context) return NULL;
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
        CGImageRef newImage = CGBitmapContextCreateImage(context);
        CFRelease(context);
        return newImage;
        
    } else {
        CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
        size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        if (bytesPerRow == 0 || width == 0 || height == 0) return NULL;
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
        if (!dataProvider) return NULL;
        CFDataRef data = CGDataProviderCopyData(dataProvider); // decode
        if (!data) return NULL;
        
        CGDataProviderRef newProvider = CGDataProviderCreateWithCFData(data);
        CFRelease(data);
        if (!newProvider) return NULL;
        
        CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, newProvider, NULL, false, kCGRenderingIntentDefault);
        CFRelease(newProvider);
        return newImage;
    }
}
@end

@implementation UIImage (YYImageCoder)

- (instancetype)yy_imageByDecoded {
    if (self.yy_isDecodedForDisplay) return self;
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) return self;
    CGImageRef newImageRef = YYCGImageCreateDecodedCopy(imageRef, YES);
    if (!newImageRef) return self;
    UIImage *newImage = [[self.class alloc] initWithCGImage:newImageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(newImageRef);
    if (!newImage) newImage = self; // decode failed, return self.
    newImage.yy_isDecodedForDisplay = YES;
    return newImage;
}

- (BOOL)yy_isDecodedForDisplay {
//    if (self.images.count > 1 || [self isKindOfClass:[YYSpriteSheetImage class]]) return YES;
    NSNumber *num = objc_getAssociatedObject(self, @selector(yy_isDecodedForDisplay));
    return [num boolValue];
}

- (void)setYy_isDecodedForDisplay:(BOOL)isDecodedForDisplay {
    objc_setAssociatedObject(self, @selector(yy_isDecodedForDisplay), @(isDecodedForDisplay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)yy_saveToAlbumWithCompletionBlock:(void(^)(NSURL *assetURL, NSError *error))completionBlock {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSData *data = [self _yy_dataRepresentationForSystem:YES];
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error){
//            if (!completionBlock) return;
//            if (pthread_main_np()) {
//                completionBlock(assetURL, error);
//            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    completionBlock(assetURL, error);
//                });
//            }
//        }];
//    });
}

- (NSData *)yy_imageDataRepresentation {
    return [self _yy_dataRepresentationForSystem:NO];
}

/// @param forSystem YES: used for system album (PNG/JPEG/GIF), NO: used for YYImage (PNG/JPEG/GIF/WebP)
- (NSData *)_yy_dataRepresentationForSystem:(BOOL)forSystem {
    NSData *data = nil;
//    if ([self isKindOfClass:[YYImage class]]) {
//        YYImage *image = (id)self;
//        if (image.animatedImageData) {
//            if (forSystem) { // system only support GIF and PNG
//                if (image.animatedImageType == YYImageTypeGIF ||
//                    image.animatedImageType == YYImageTypePNG) {
//                    data = image.animatedImageData;
//                }
//            } else {
//                data = image.animatedImageData;
//            }
//        }
//    }
//    if (!data) {
//        CGImageRef imageRef = self.CGImage ? (CGImageRef)CFRetain(self.CGImage) : nil;
//        if (imageRef) {
//            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
//            CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
//            BOOL hasAlpha = NO;
//            if (alphaInfo == kCGImageAlphaPremultipliedLast ||
//                alphaInfo == kCGImageAlphaPremultipliedFirst ||
//                alphaInfo == kCGImageAlphaLast ||
//                alphaInfo == kCGImageAlphaFirst) {
//                hasAlpha = YES;
//            }
//            if (self.imageOrientation != UIImageOrientationUp) {
//                CGImageRef rotated = YYCGImageCreateCopyWithOrientation(imageRef, self.imageOrientation, bitmapInfo | alphaInfo);
//                if (rotated) {
//                    CFRelease(imageRef);
//                    imageRef = rotated;
//                }
//            }
//            @autoreleasepool {
//                UIImage *newImage = [UIImage imageWithCGImage:imageRef];
//                if (newImage) {
//                    if (hasAlpha) {
//                        data = UIImagePNGRepresentation([UIImage imageWithCGImage:imageRef]);
//                    } else {
//                        data = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.9); // same as Apple's example
//                    }
//                }
//            }
//            CFRelease(imageRef);
//        }
//    }
//    if (!data) {
//        data = UIImagePNGRepresentation(self);
//    }
    return data;
}

@end
