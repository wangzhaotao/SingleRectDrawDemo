//
//  TJPointCircleView.m
//  OpenCVRectDectectDemo
//
//  Created by WZT on 2017/3/20.
//  Copyright © 2017年 WZT. All rights reserved.
//

#import "TJPointCircleView.h"
#import "TJLineModel.h"


@interface TJPointCircleView ()<TJRectModelDelegate>
{
    NSInteger currentPointIndex;
}
@property (nonatomic, assign, readwrite) BOOL isInQuadrilateral;     //是否是内四边形
@property (nonatomic, copy, readwrite) NSMutableArray <TJRectModel*>*rectsArray;

@property (nonatomic, strong) TJRectModel *currentRectModel;


@end

@implementation TJPointCircleView

#pragma mark 初始化方法
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark public methods
//限制只进行矩形位移
-(void)setIsOnlyRectMoving:(BOOL)isOnlyRectMoving {
    _isOnlyRectMoving = isOnlyRectMoving;
    for (TJRectModel *rectMode in self.rectsArray) {
        rectMode.isOnlyRectMoving = isOnlyRectMoving;
    }
}
//清空之前的绘制
-(void)clearBeforeCircleAndLines {
    [self.rectsArray removeAllObjects];
    [self setNeedsDisplay];
}
-(void)addARect {
    
    CGFloat imgW = 200, imgH = 150;
    CGFloat origin_x = (self.bounds.size.width-imgW)/2,
    origin_y = (self.bounds.size.height-imgH)/2;
    NSArray *points = @[
                        @[[NSNumber numberWithFloat:origin_x],[NSNumber numberWithFloat:origin_y]],
                        @[[NSNumber numberWithFloat:origin_x+imgW],[NSNumber numberWithFloat:origin_y]],
                        @[[NSNumber numberWithFloat:origin_x],[NSNumber numberWithFloat:origin_y+imgH]],
                        @[[NSNumber numberWithFloat:origin_x+imgW],[NSNumber numberWithFloat:origin_y+imgH]]
                        ];
    //
    TJRectModel *rectModel = [self createRectModel];
    rectModel.pointsArray = [NSMutableArray arrayWithArray:points];
    [self.rectsArray addObject:rectModel];
    
    self.currentRectModel = rectModel;
    [self setNeedsDisplay];
}
//起点 宽高
-(void)addRectWithOrigin:(CGPoint)origin width:(NSInteger)width height:(NSInteger)height {
    
    NSArray *points = @[
                        @[[NSNumber numberWithFloat:origin.x],[NSNumber numberWithFloat:origin.y]],
                        @[[NSNumber numberWithFloat:origin.x+width],[NSNumber numberWithFloat:origin.y]],
                        @[[NSNumber numberWithFloat:origin.x],[NSNumber numberWithFloat:origin.y+height]],
                        @[[NSNumber numberWithFloat:origin.x+width],[NSNumber numberWithFloat:origin.y+height]]
                        ];
    [self addARectWithPoints:points];
}
-(void)addARectWithPoints:(NSArray*)points {
    
    //调整ABCD点的顺序
    //重新确定四个边角点顺序
    if (points.count>=4) {
        NSMutableArray *temp = [[points subarrayWithRange:NSMakeRange(0, 4)] mutableCopy];
        
        TJRectModel *rectModel = [self createRectModel];
        rectModel.pointsArray = [NSMutableArray arrayWithArray:temp];
        [self.rectsArray addObject:rectModel];
        
        self.currentRectModel = rectModel;
        [self setNeedsDisplay];
    }
}

#pragma mark set get函数
-(NSMutableArray<TJRectModel*>*)rectsArray {
    if (!_rectsArray) {
        _rectsArray = [NSMutableArray array];
    }
    return _rectsArray;
}
-(TJRectModel*)createRectModel {
    TJRectModel *rectModel = [TJRectModel new];
    rectModel.max_width = self.bounds.size.width;
    rectModel.max_height = self.bounds.size.height;
    rectModel.delegate = self;
    rectModel.isOnlyRectMoving = _isOnlyRectMoving;
    
    return rectModel;
}

#pragma mark private methods
-(TJRectModel*)searchRectModelWithPoint:(CGPoint)point {
    
    TJRectModel *touchModel = nil;
    for (TJRectModel *model in self.rectsArray) {
        BOOL touch = [model isTouchRectWithPoint:point];
        if (touch) {
            touchModel = model;
            break;
        }
    }
    return touchModel;
}


#pragma mark 重写手势操作接口
//重写touch
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    for (TJRectModel *model in self.rectsArray) {
        if ([model isTouchRectWithPoint:p]) {
            self.currentRectModel = model;//[self searchRectModelWithPoint:p];
            if (self.currentRectModel) {
                [self.currentRectModel touchBeginWithPoint:p];
            }
            
            return;
        }
    }
    self.currentRectModel = nil;
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    if (self.currentRectModel) {
        [self.currentRectModel touchMovingWithPoint:p];
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    //重新确定四个边角点顺序
    if (self.currentRectModel) {
        [self.currentRectModel touchEndWithPoint:CGPointZero];
    }
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    //检测是否为内四边形
    if (self.currentRectModel) {
        [self.currentRectModel touchCancelWithPoint:CGPointZero];
    }
}


#pragma mark 清空上下文绘制

#pragma mark 重写drawRect:
- (void)drawRect:(CGRect)rect {
    if (self.rectsArray.count==0) {
        return;
    }
    
    for (TJRectModel *model in self.rectsArray) {
        [model redraw];
    }
}


#pragma mark TJRectModelDelegate
-(void)redrawRect {
    
    [self setNeedsDisplay];
}



@end
